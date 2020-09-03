# Packages -----------------------------------------------------------------
require(EpiNow2, quietly = TRUE)
require(covidregionaldata, quietly = TRUE)
require(data.table, quietly = TRUE)
require(future, quietly = TRUE)
require(here, quietly = TRUE)
require(lubridate, quietly = TRUE)
require(futile.logger, quietly = TRUE)

# Load utils --------------------------------------------------------------

source(here::here("R", "utils.R"))

# Update delays -----------------------------------------------------------

generation_time <- readRDS(here::here("data", "generation_time.rds"))
incubation_period <- readRDS(here::here("data", "incubation_period.rds"))
reporting_delay <- readRDS(here::here("data", "onset_to_admission_delay.rds"))

# Set up logging ----------------------------------------------------------

setup_log()

futile.logger::flog.info("Processing national dataset for: cases")

# Get cases  ---------------------------------------------------------------

cases <- data.table::setDT(covidregionaldata::get_national_data(source = "ecdc"))


# Make regional case dataset ----------------------------------------------

regional_cases <- data.table::copy(cases)[, .(cases_new = sum(cases_new, na.rm = TRUE)),
                                                   by = c("date", "un_region")][, region := un_region]
global_cases <- data.table::copy(regional_cases)[, .(cases_new = sum(cases_new, na.rm = TRUE)),
                                                 by = c("date")][, region := "Global"]
regional_cases <- data.table::rbindlist(list(regional_cases, global_cases), 
                                        fill = TRUE, use.names = TRUE)

# Process cases -----------------------------------------------------------

cases <- cases[, region := country]
cases <- clean_regional_data(cases)

regional_cases <- clean_regional_data(regional_cases)

# Check to see if the data has been updated  ------------------------------

if (check_for_update(cases, last_run = here::here("last-update", "cases.rds"))) {

  # Run Rt estimation -------------------------------------------------------
  national_epinow <- function(cases, target, summary, scale,
                              no_cores) {
    regional_epinow_with_settings(reported_cases = cases,
                                  generation_time = generation_time,
                                  delays = list(incubation_period, reporting_delay),
                                  no_cores = no_cores,
                                  target_dir = target,
                                  summary_dir = summary,
                                  region_summary = FALSE,
                                  region_scale = scale)
    
  }

  ## Run UN and global estimate
  no_cores <- setup_future(length(unique(regional_cases$region)))
  
  national_epinow(cases = regional_cases,
                  target = "region/cases/region",
                  summary = "region/cases/summary",
                  scale = "Region",
                  no_cores = no_cores)
  
  ## Run national estimates
  no_cores <- setup_future(length(unique(cases$region)))
  
  national_epinow(cases = cases,
                  target = "national/cases/national",
                  summary = "national/cases/summary",
                  scale = "Country",
                  no_cores = no_cores)

}
