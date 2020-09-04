# Packages -----------------------------------------------------------------
require(EpiNow2, quietly = TRUE)
require(covidregionaldata, quietly = TRUE)
require(data.table, quietly = TRUE)
require(future, quietly = TRUE)
require(lubridate, quietly = TRUE)
require(futile.logger, quietly = TRUE)

# Load utils --------------------------------------------------------------

source(here::here("R", "utils.R"))

# Update delays -----------------------------------------------------------

generation_time <- readRDS(here::here("data", "generation_time.rds"))
incubation_period <- readRDS(here::here("data", "incubation_period.rds"))
reporting_delay <- readRDS(here::here("data", "onset_to_death_delay.rds"))

# Set up logging ----------------------------------------------------------

setup_log()

futile.logger::flog.info("Processing national dataset for: deaths")

# Get deaths  ---------------------------------------------------------------

deaths <- data.table::setDT(covidregionaldata::get_national_data(source = "ecdc"))
deaths <- deaths[country != "Cases_on_an_international_conveyance_Japan"]
deaths <- deaths[, cases_new := deaths_new]

# Make regional case dataset ----------------------------------------------

regional_deaths <- data.table::copy(deaths)[, .(cases_new = sum(cases_new, na.rm = TRUE)),
                                          by = c("date", "un_region")][, region := un_region]
global_deaths <- data.table::copy(regional_deaths)[, .(cases_new = sum(cases_new, na.rm = TRUE)),
                                                 by = c("date")][, region := "Global"]
regional_deaths <- data.table::rbindlist(list(regional_deaths, global_deaths), 
                                         fill = TRUE, use.names = TRUE)

# Process cases -----------------------------------------------------------

deaths <- deaths[, region := country]
deaths <- clean_regional_data(deaths)

regional_deaths <- clean_regional_data(regional_deaths)

# Check to see if the data has been updated  ------------------------------

if (check_for_update(deaths, last_run = here::here("last-update", "deaths.rds"))) {

  # Run Rt estimation -------------------------------------------------------
  national_epinow <- function(cases, target, summary, scale,
                              no_cores) {
    regional_epinow_with_settings(reported_cases = cases,
                                  generation_time = generation_time,
                                  delays = list(incubation_period, reporting_delay),
                                  no_cores = no_cores,
                                  target_dir = target,
                                  summary_dir = summary,
                                  region_scale = scale,
                                  region_summary = FALSE)
    
  }
  
  ## Run UN and global estimate
  no_cores <- setup_future(length(unique(regional_deaths$region)))
  
  national_epinow(cases = regional_deaths,
                  target = "region/deaths/region",
                  summary = "region/deaths/summary",
                  scale = "Region",
                  no_cores = no_cores)
  
  ## Run national estimates
  no_cores <- setup_future(length(unique(deaths$region)))
  
  national_epinow(cases = deaths,
                  target = "national/deaths/national",
                  summary = "national/deaths/summary",
                  scale = "Country")
}
