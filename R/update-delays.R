# Packages ----------------------------------------------------------------

require(EpiNow2)
require(covidregionaldata)
require(data.table)
require(future)
require(lubridate)

# Save incubation period and generation time ------------------------------

generation_time <- list(mean = EpiNow2::covid_generation_times[1, ]$mean,
                        mean_sd = EpiNow2::covid_generation_times[1, ]$mean_sd,
                        sd = EpiNow2::covid_generation_times[1, ]$sd,
                        sd_sd = EpiNow2::covid_generation_times[1, ]$sd_sd,
                        max = 30)

incubation_period <- list(mean = EpiNow2::covid_incubation_period[1, ]$mean,
                          mean_sd = EpiNow2::covid_incubation_period[1, ]$mean_sd,
                          sd = EpiNow2::covid_incubation_period[1, ]$sd,
                          sd_sd = EpiNow2::covid_incubation_period[1, ]$sd_sd,
                          max = 30)


saveRDS(generation_time , here::here("data", "generation_time.rds"))
saveRDS(incubation_period, here::here("data", "incubation_period.rds"))


# Set up parallel ---------------------------------------------------------

if (!interactive()) {
  ## If running as a script enable this
  options(future.fork.enable = TRUE)
}


plan(multiprocess)

# Fit delay from onset to admission ---------------------------------------

report_delay <- covidregionaldata::get_linelist(report_delay_only = TRUE)
report_delay <- data.table::as.data.table(report_delay)[!(country %in% c("Mexico", "Phillipines"))]

onset_to_admission_delay <- EpiNow2::bootstrapped_dist_fit(report_delay$days_onset_to_report, bootstraps = 100, 
                                                           bootstrap_samples = 250)
## Set max allowed delay to 30 days to truncate computation
onset_to_admission_delay$max <- 30

saveRDS(onset_to_admission_delay, here::here("data", "onset_to_admission_delay.rds"))

# Fit delay from onset to deaths ------------------------------------------
# Not used as of the 28th of July the linelist only contains 6 complete records.
# death_delay <- data.table::setDT(covidregionaldata::get_linelist(clean = FALSE))
# death_delay <- death_delay[outcome %in% "death"][!is.na(date_death_or_discharge)][!is.na(date_onset_symptoms)]
# death_delay <- death_delay[, .(date_death = lubridate::dmy(date_death_or_discharge), 
#                                date_onset = lubridate::dmy(date_onset_symptoms))][,
#                                delay := as.numeric(date_death - date_onset)]
# 
# onset_to_death_delay <- EpiNow2::bootstrapped_dist_fit(deaths, bootstraps = 100, bootstrap_samples = 250)
# 
# ## Set max allowed delay to 30 days to truncate computation
# onset_to_death_delay$max <- 30
# 
# saveRDS(onset_to_death_delay, here::here("data", "onset_to_death_delay.rds"))