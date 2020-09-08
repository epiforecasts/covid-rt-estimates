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

  futile.logger::flog.info("Processing regional dataset for %s", location$name)

  # Update delays -----------------------------------------------------------
  if (is.na(location$generation_time)) {
    location$generation_time <- readRDS(here::here("data", "generation_time.rds"))
  }
  if (is.na(location$incubation_period)) {
    location$incubation_period <- readRDS(here::here("data", "incubation_period.rds"))
  }
  if (is.na(location$reporting_delay)) {
    location$reporting_delay <- readRDS(here::here("data", "onset_to_admission_delay.rds"))
  }

  # Get cases  ---------------------------------------------------------------
  futile.logger::flog.info("Getting regional data")

  if (is.na(location$covid_regional_data_identifier)) {
    location$covid_regional_data_identifier <- location$name
  }

  cases <- data.table::setDT(covidregionaldata::get_regional_data(country = location$covid_regional_data_identifier,
                                                                  localise_regions = FALSE))

  if (!is.na(location$case_modifier) &&
    typeof(location$case_modifier) == "closure") {
    futile.logger::flog.trace("Modifying regional data")
    cases <- location$case_modifier(cases)
  }
  if (!is.na(location$cases_subregion_source)) {
    if (!location$cases_subregion_source %in% colnames(cases)) {
      futile.logger::flog.error("invalid source column name %s - only the following are valid", location$cases_subregion_source)
      futile.logger::flog.error(colnames(cases))
      stop("Invalid column name")
    }
    futile.logger::flog.trace("Remapping case data with %s as region source", location$cases_subregion_source)
    data.table::setnames(cases, location$cases_subregion_source, "region")
  }
  if (excludes[, .N] > 0) {
    futile.logger::flog.trace("Filtering out excluded regions")
    cases <- cases[!(region %in_ci% excludes$subregion)]
  }
  if (includes[, .N] > 0 && !("*" %in% includes$subregion)) {
    futile.logger::flog.trace("Filtering out not included regions")
    cases <- cases[region %in_ci% includes$subregion]
  }
  futile.logger::flog.trace("Cleaning regional data")
  cases <- clean_regional_data(cases)

  # Check to see if there is data and if the data has been updated  ------------------------------
  if (cases[, .N] > 0 && (force || check_for_update(cases, last_run = here::here("last-update", paste0(location$name, ".rds"))))) {

    # Set up cores -----------------------------------------------------
    no_cores <- setup_future(length(unique(cases$region)))
    # Run Rt estimation -------------------------------------------------------
    out <- regional_epinow_with_settings(reported_cases = cases,
                                  generation_time = location$generation_time,
                                  delays = list(location$incubation_period, location$reporting_delay),
                                  no_cores = no_cores,
                                  target_dir = paste0("subnational/", location$name, "/cases/national"),
                                  summary_dir = paste0("subnational/", location$name, "/cases/summary"),
                                  region_scale = location$region_scale,
                                  max_execution_time = max_execution_time)
  } else if (cases[, .N] == 0) {
    futile.logger::flog.warning("no cases left for region so not processing!")
    out <- list()
  }
  return(out)
}
