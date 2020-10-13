source(here::here("R", "entities.R"))

# This list is processed in order when doing a full run.
# Order is defined as follows:
# 1. Priority
# 2. ABC

datasets <- c(
  Region$new(name = "united-kingdom", # leaving this as the default UK for historic purposes
             publication_metadata = PublicationMetadata$new(
               title = "United Kingdom R Rate Estimates Based on Reported Test Results",
               description = "Calculations based on the Government postive cases for an x week rolling window. Note this is impacted by test availability.",
               breakdown = "region",
               country = "United Kingdom"),
             covid_regional_data_identifier = "UK",
             case_modifier = function(cases) {
               cases <- add_uk(cases)
               return(cases) },
             data_args = list(nhsregions = TRUE)),
  Region$new(name = "united-kingdom-deaths",
             publication_metadata = PublicationMetadata$new(
               title = "United Kingdom R Rate Estimates Based on Reported Deaths",
               description = "Calculations based on the Government reported deaths within 28 days of a positive test",
               breakdown = "region",
               country = "United Kingdom"),
             covid_regional_data_identifier = "UK",
             folder_name = "united-kingdom",
             dataset_folder_name = "deaths",
             reporting_delay = readRDS(here::here("data", "cocin_onset_to_death_delay.rds")),
             case_modifier = function(deaths) {
               deaths <- deaths[, cases_new := deaths_new]
               deaths <- add_uk(deaths)
               return(deaths) },
             data_args = list(nhsregions = TRUE)),
  Region$new(name = "united-kingdom-admissions",
             publication_metadata = PublicationMetadata$new(
               title = "United Kingdom R Rate Estimates Based on Hospital Admissions",
               description = "Calculations based on the NHS covid admissions",
                breakdown = "region",
                country = "United Kingdom"),
             covid_regional_data_identifier = "UK",
             folder_name = "united-kingdom",
             dataset_folder_name = "admissions",
             case_modifier = function(admissions) {
               admissions <- admissions[, cases_new := hosp_new_blend]
               return(admissions) },
             data_args = list(nhsregions = TRUE)),
  Region$new(name = "united-states",
             publication_metadata = PublicationMetadata$new(
               title = "United States R Rate Estimates Based on Positive Tests",
               description = "...",
                breakdown = "state",
                country = "United States"),
             covid_regional_data_identifier = "USA",
             region_scale = "State"),
  SuperRegion$new(name = "regional-cases",
                  publication_metadata = PublicationMetadata$new(
                    title = "Continent Summary R Rate Based on Reported Cases",
                    description = "...",
                breakdown = "continent"),
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
                  publication_metadata = PublicationMetadata$new(
                    title = "Continent Summary R Rate Based on Reported Deaths",
                    description = "Calculations based on the Government postive cases for an x week rolling window",
                breakdown = "continent"),
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
                  publication_metadata = PublicationMetadata$new(
                    title = "Cases R Rate Based on Reported Cases",
                    description = "Calculations based on the Government postive cases for an x week rolling window",
                breakdown = "country"),
                  case_modifier = function(cases) {
                    cases <- cases[, region := country]
                  }),
  SuperRegion$new(name = "deaths",
                  publication_metadata = PublicationMetadata$new(
                    title = "Deaths R Rate Based on Reported Deaths",
                    description = "Calculations based on the Government postive cases for an x week rolling window",
                breakdown = "country"),
                  case_modifier = function(deaths) {
                    deaths <- deaths[country != "Cases_on_an_international_conveyance_Japan"]
                    deaths <- deaths[, cases_new := deaths_new]
                    deaths <- deaths[, region := country]
                  }),
  Region$new(name = "afghanistan",
             publication_metadata = PublicationMetadata$new(
               title = "afghanistan R Rate Based on Reported Cases",
               description = "Calculations based on the Government postive cases for an x week rolling window",
                breakdown = "state",
                country = "Afghanistan"),
             case_modifier = function(cases) {
               cases <- cases[!is.na(iso_3166_2)]
               return(cases)
             },
             stable = FALSE),
  Region$new(name = "belgium",
             publication_metadata = PublicationMetadata$new(
               title = "belgium R Rate Based on Reported Cases",
               description = "Calculations based on the Government postive cases for an x week rolling window",
                breakdown = "state",
                country = "Belgium")),
  Region$new(name = "brazil",
             publication_metadata = PublicationMetadata$new(
               title = "brazil R Rate Based on Reported Cases",
               description = "Calculations based on the Government postive cases for an x week rolling window",
                breakdown = "state",
                country = "Brazil")),
  Region$new(name = "canada",
             publication_metadata = PublicationMetadata$new(
               title = "canada R Rate Based on Reported Cases",
               description = "Calculations based on the Government postive cases for an x week rolling window",
                breakdown = "state",
                country = "Canada")),
  Region$new(name = "colombia",
             publication_metadata = PublicationMetadata$new(
               title = "colombia R Rate Based on Reported Cases",
               description = "Calculations based on the Government postive cases for an x week rolling window",
                breakdown = "state",
                country = "Colombia")),
  Region$new(name = "germany",
             publication_metadata = PublicationMetadata$new(
               title = "germany R Rate Based on Reported Cases",
               description = "Calculations based on the Government postive cases for an x week rolling window",
                breakdown = "region",
                country = "Germany")),
  Region$new(name = "india",
             publication_metadata = PublicationMetadata$new(
               title = "india R Rate Based on Reported Cases",
               description = "Calculations based on the Government postive cases for an x week rolling window",
                breakdown = "state",
                country = "India")),
  Region$new(name = "italy",
             publication_metadata = PublicationMetadata$new(
               title = "italy R Rate Based on Reported Cases",
               description = "Calculations based on the Government postive cases for an x week rolling window",
                breakdown = "state",
                country = "Italy")),
  Region$new(name = "russia",
             publication_metadata = PublicationMetadata$new(
               title = "russia R Rate Based on Reported Cases",
               description = "Calculations based on the Government postive cases for an x week rolling window",
                breakdown = "state",
                country = "Russian Federation"))
)
