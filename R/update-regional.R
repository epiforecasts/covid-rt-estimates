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
update_regional <- function(location, excludes, includes, force, max_execution_time) {

  futile.logger::flog.info("Processing dataset for %s", location$name)

  # Update delays -----------------------------------------------------------
  if (is.na(location$generation_time)) {
    location$generation_time <- readRDS(here::here("data", "generation_time.rds"))
  }
  if (is.na(location$incubation_period)) {
    location$incubation_period <- readRDS(here::here("data", "incubation_period.rds"))
  }
  if (is.na(location$reporting_delay)) {
    if (location$name %in% c("deaths", "regional-deaths")) {
      location$reporting_delay <- readRDS(here::here("data", "onset_to_death_delay.rds"))
    }
    else {
      location$reporting_delay <- readRDS(here::here("data", "onset_to_admission_delay.rds"))
    }
  }

  # Get cases  ---------------------------------------------------------------

  if ("Region" %in% class(location)) {
    if (is.na(location$covid_regional_data_identifier)) {
      location$covid_regional_data_identifier <- location$name
    }
    futile.logger::flog.info("Getting regional data")
    cases <- data.table::setDT(covidregionaldata::get_regional_data(country = location$covid_regional_data_identifier,
                                                                    localise_regions = FALSE))
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

  cases <- clean_regional_data(cases)

  # Check to see if there is data and if the data has been updated  ------------------------------
  if (cases[, .N] > 0 && (force || check_for_update(cases, last_run = here::here("last-update", paste0(location$name, ".rds"))))) {
    # Set up cores -----------------------------------------------------
    no_cores <- setup_future(length(unique(cases$region)))
    # Run Rt estimation -------------------------------------------------------
    futile.logger::flog.trace("calling regional_epinow")
    out <- regional_epinow(reported_cases = cases,
                           generation_time = location$generation_time,
                           delays = list(location$incubation_period, location$reporting_delay),
                           non_zero_points = 14, horizon = 14,
                           burn_in = 14, samples = 4000,
                           warmup = 500, fixed_future_rt = TRUE, cores = no_cores,
                           chains = ifelse(no_cores <= 2, 2, no_cores),
                           target_folder = location$target_folder,
                           summary_dir = location$summary_dir,
                           region_scale = location$region_scale,
                           return_estimates = FALSE,
                           verbose = FALSE,
                           all_regions_summary = "Region" %in% class(location),
                           return_timings = TRUE,
                           max_execution_time = max_execution_time)
    futile.logger::flog.debug("resetting future plan to sequential")
    future::plan("sequential")
  } else {
    out <- list()
  }
  if (cases[, .N] == 0) {
    futile.logger::flog.warning("no cases left for region so not processing!")
  }
  return(out)
}
