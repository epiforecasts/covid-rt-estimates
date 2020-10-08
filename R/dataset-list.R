source(here::here("R", "entities.R"))

# This list is processed in order when doing a full run.
# Order is defined as follows:
# 1. Priority
# 2. ABC

datasets <- c(
  Region$new(name = "united-kingdom", # leaving this as the default UK for historic purposes
             covid_regional_data_identifier = "UK",
             case_modifier = function(cases) {
               national_cases <- cases[region_level_1 %in% c("England", "Scotland", "Wales", "Northern Ireland")]
               uk_cases <- data.table::copy(national_cases)[, .(cases_new = sum(cases_new, na.rm = TRUE)),
                                                              by = c("date")][, region_level_1 := "United Kingdom"]
               cases <- data.table::rbindlist(list(cases, uk_cases),
                                               fill = TRUE, use.names = TRUE)},
             data_args = list(nhsregions = TRUE)),
  Region$new(name = "united-kingdom-deaths",
             covid_regional_data_identifier = "UK",
             folder_name = "united-kingdom",
             dataset_folder_name = "deaths",
             reporting_delay = readRDS(here::here("data", "cocin_onset_to_death_delay.rds")),
             case_modifier = function(deaths) {
               deaths <- deaths[, cases_new := deaths_new]
               national_deaths <- deaths[region_level_1 %in% c("England", "Scotland", "Wales", "Northern Ireland")]
               uk_deaths <- data.table::copy(national_deaths)[, .(cases_new = sum(cases_new, na.rm = TRUE)),
                                                              by = c("date")][, region_level_1 := "United Kingdom"]
               deaths <- data.table::rbindlist(list(deaths, uk_deaths),
                                                   fill = TRUE, use.names = TRUE)},
             data_args = list(nhsregions = TRUE)),
  Region$new(name = "united-kingdom-admissions",
             covid_regional_data_identifier = "UK",
             folder_name = "united-kingdom",
             dataset_folder_name = "admissions",
             case_modifier = function(admissions) {
               admissions <- admissions[, cases_new := hosp_new_blend]
               national_admissions <- admissions[region_level_1 %in% c("England", "Scotland", "Wales", "Northern Ireland")]
               uk_admissions <- data.table::copy(national_admissions)[, .(cases_new = sum(cases_new, na.rm = TRUE)),
                                                                by = c("date")][, region_level_1 := "United Kingdom"]
               admissions <- data.table::rbindlist(list(admissions, uk_admissions),
                                                       fill = TRUE, use.names = TRUE)},
             data_args = list(nhsregions = TRUE)),
  Region$new(name = "united-states",
             covid_regional_data_identifier = "USA",
             region_scale = "State"),
  SuperRegion$new(name = "regional-cases",
                  region_scale = "Region",
                  folder_name = "cases",
                  case_modifier = function(regional_cases) {
                    regional_cases <- regional_cases[, .(cases_new = sum(cases_new, na.rm = TRUE)),
                                                       by = c("date", "un_region")][, region := un_region]
                    global_cases <- data.table::copy(regional_cases)[, .(cases_new = sum(cases_new, na.rm = TRUE)),
                                                                       by = c("date")][, region := "Global"]
                    regional_cases <- data.table::rbindlist(list(regional_cases, global_cases),
                                                            fill = TRUE, use.names = TRUE)
                  }),
  SuperRegion$new(name = "regional-deaths",
                  region_scale = "Region",
                  folder_name = "deaths",
                  case_modifier = function(regional_deaths) {
                    regional_deaths <- regional_deaths[country != "Cases_on_an_international_conveyance_Japan"]
                    regional_deaths <- regional_deaths[, cases_new := deaths_new]
                    regional_deaths <- regional_deaths[, .(cases_new = sum(cases_new, na.rm = TRUE)),
                                                         by = c("date", "un_region")][, region := un_region]
                    global_deaths <- data.table::copy(regional_deaths)[, .(cases_new = sum(cases_new, na.rm = TRUE)),
                                                                         by = c("date")][, region := "Global"]
                    regional_deaths <- data.table::rbindlist(list(regional_deaths, global_deaths),
                                                             fill = TRUE, use.names = TRUE)
                  }),
  SuperRegion$new(name = "cases",
                  case_modifier = function(cases) {
                    cases <- cases[, region := country]
                  }),
  SuperRegion$new(name = "deaths",
                  case_modifier = function(deaths) {
                    deaths <- deaths[country != "Cases_on_an_international_conveyance_Japan"]
                    deaths <- deaths[, cases_new := deaths_new]
                    deaths <- deaths[, region := country]
                  }),
  Region$new(name = "afghanistan",
             case_modifier = function(cases) {
               cases <- cases[!is.na(iso_3166_2)]
               return(cases)
             },
             stable = FALSE),
  Region$new(name = "belgium"),
  Region$new(name = "brazil"),
  Region$new(name = "canada"),
  Region$new(name = "colombia"),
  Region$new(name = "germany"),
  Region$new(name = "india"),
  Region$new(name = "italy"),
  Region$new(name = "russia")
)
