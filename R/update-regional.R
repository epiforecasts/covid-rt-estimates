# Packages -----------------------------------------------------------------
require(EpiNow2, quietly = TRUE)
require(covidregionaldata, quietly = TRUE)
require(data.table, quietly = TRUE)
require(future, quietly = TRUE)
require(lubridate, quietly = TRUE)

# Load utils --------------------------------------------------------------

source(here::here("R", "utils.R"))


#' Update Regional
#'
#' @description Processes regional data in an abstract fashion to reduce code duplication
#' @param location Location object containing information about region
#' @param excludes Dataframe containing regions to exclude
#' @param includes Dataframe containing the only regions to include
#' @param max_execution_time Integer specifying the timeout in seconds
update_regional <- function(location, excludes, includes, force, max_execution_time, refresh) {

  futile.logger::flog.info("Processing dataset for %s", location$name)
  futile.logger::flog.trace("loading ancillary data")
  # Update delays -----------------------------------------------------------
  if (!is.list(location$generation_time)) {
    futile.logger::flog.trace("loading generation_time.rds")
    location$generation_time <- readRDS(here::here("data", "generation_time.rds"))
  }
  if (!is.list(location$incubation_period)) {
    futile.logger::flog.trace("loading incubation_period.rds")
    location$incubation_period <- readRDS(here::here("data", "incubation_period.rds"))
  }
  if (!is.list(location$reporting_delay)) {
    if (location$name %in% c("deaths", "regional-deaths")) {
      futile.logger::flog.trace("loading onset_to_death_delay.rds")
      location$reporting_delay <- readRDS(here::here("data", "onset_to_death_delay.rds"))
    }
    else {
      futile.logger::flog.trace("loading onset_to_admission_delay.rds")
      location$reporting_delay <- readRDS(here::here("data", "onset_to_admission_delay.rds"))
    }
  }

  # Get cases  ---------------------------------------------------------------
  futile.logger::flog.trace("loading cases")
  if ("Region" %in% class(location)) {
    if (is.na(location$covid_regional_data_identifier)) {
      location$covid_regional_data_identifier <- location$name
    }
    futile.logger::flog.info("Getting regional data")

    cases <- do.call(covidregionaldata::get_regional_data, c(list(country = location$covid_regional_data_identifier,
                                                                  localise_regions = FALSE),
                                                             location$data_args))
    cases <- data.table::setDT(cases)
  }else if ("SuperRegion" %in% class(location)) {
    futile.logger::flog.info("Getting national data", location$name)
    cases <- data.table::setDT(covidregionaldata::get_national_data(source = location$covid_national_data_identifier))
  }

  if (typeof(location$case_modifier) == "closure") {
    futile.logger::flog.trace("Modifying data")
    cases <- location$case_modifier(cases)
  }

  # Rename columns -------------------------------------------------------------

  if (exists("cases_subregion_source", location) && !is.na(location$cases_subregion_source)) {
    if (!location$cases_subregion_source %in% colnames(cases)) {
      futile.logger::flog.error("invalid source column name %s - only the following are valid", location$cases_subregion_source)
      futile.logger::flog.error(colnames(cases))
      stop("Invalid column name")
    }
    futile.logger::flog.trace("Remapping case data with %s as region source", location$cases_subregion_source)
    data.table::setnames(cases, location$cases_subregion_source, "region")
  }

  # Exclude unwanted locations and clean data -------------------------------------------------

  if (excludes[, .N] > 0) {
    futile.logger::flog.trace("Filtering out excluded regions")
    cases <- cases[!(region %in_ci% excludes$subregion)]
  }
  if (includes[, .N] > 0 && !("*" %in% includes$subregion)) {
    futile.logger::flog.trace("Filtering out not included regions")
    cases <- cases[region %in_ci% includes$subregion]
  }

  cases <- clean_regional_data(cases, truncation = location$truncation)

  # Check to see if there is data and if the data has been updated  ------------------------------
  if (cases[, .N] > 0 && (force || check_for_update(cases, last_run = here::here("last-update", paste0(location$name, ".rds"))))) {
    # Set up cores -----------------------------------------------------
    no_cores <- setup_future(length(unique(cases$region)))

    if (refresh) {
      if (dir.exists(location$target_folder)) {
        futile.logger::flog.trace("removing estimates in order to refresh")
        unlink(location$target_folder, recursive = TRUE)
      }
    }
    # Run Rt estimation -------------------------------------------------------
    futile.logger::flog.trace("calling regional_epinow")
    regional_epinow(reported_cases = cases,
                    generation_time = location$generation_time,
                    delays = list(location$incubation_period, location$reporting_delay),
                    non_zero_points = 14, 
                    horizon = 14, 
                    burn_in = 14, 
                    samples = 4000,
                    stan_args = list(warmup = 500, cores = no_cores,
                                     chains = ifelse(no_cores <= 4, 4, no_cores)),
                    future_rt = "latest",
                    target_folder = location$target_folder,
                    future = TRUE,
                    max_execution_time = max_execution_time,
                    summary_args = list(
                      summary_dir = location$summary_dir,
                      region_scale = location$region_scale,
                      all_regions = "Region" %in% class(location)))
    futile.logger::flog.debug("resetting future plan to sequential")
    future::plan("sequential")

    futile.logger::flog.trace("generating summary data")
    regional_summary(
      reported_cases = cases,
      results_dir = location$target_folder,
      summary_dir = location$summary_dir,
      region_scale = location$region_scale,
      all_regions = "Region" %in% class(location),
      return_output = FALSE
    )
    out <- list()
    futile.logger::flog.trace("reading runtimes.csv")
    timings <- data.table::fread(paste0(location$target_folder, "/runtimes.csv"))
    out <- as.list(timings$time)
    futile.logger::flog.trace("naming output")
    names(out) <- timings$region
  } else {
    out <- list()
  }
  if (cases[, .N] == 0) {
    futile.logger::flog.warning("no cases left for region so not processing!")
  }
  # add some stats
  futile.logger::flog.debug("add stats to output")
  out$max_data_date <- max(cases$date, na.rm = TRUE)
  out$oldest_results <- tryCatch(
    min(
      strptime(
        strsplit(
          system(
            paste0('for f in ', location$target_folder, '/*/latest/summary.rds; do git log -n 1 --pretty=format:"%ad" --date=iso -- "$f" 2>/dev/null; done'),
            intern = TRUE),
          '\\+\\d\\d\\d\\d',
          perl = TRUE
        )[[1]],
        "%Y-%m-%d %H:%M:%S ")
    )
    , error = function(e) {
      futile.logger::flog.debug("git not working - try stat")
      tryCatch(
        min(
          strptime(
            strsplit(
              system(
                paste0('for f in ', location$target_folder, '/*/latest/summary.rds; do stat -c %y $f; done'),
                intern = TRUE),
              '\\+\\d\\d\\d\\d',
              perl = TRUE
            )[[1]],
            "%Y-%m-%d %H:%M:%S ")
        )
        , error = function(e) {
          futile.logger::flog.debug("stat failed, just use sys.date")
          Sys.Date()
        }
      )
    }
  )

  return(out)
}
