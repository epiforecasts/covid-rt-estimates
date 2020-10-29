source(here::here("R", "entities.R"))

# This list is processed in order when doing a full run.
# Order is defined as follows:
# 1. Priority
# 2. ABC

datasets <- c(
  Region$new(name = "united-kingdom", # leaving this as the default UK for historic purposes
             publication_metadata = PublicationMetadata$new(
               title = "National and Subnational Estimates of the Covid 19 Reproduction Number (R) for the United Kingdom Based on Test Results",
               description = "Identifying changes in the reproduction number, rate of spread, and doubling time during the course of the COVID-19 outbreak whilst accounting for potential biases due to delays in case reporting both nationally and subnationally in the United Kingdom. These results are impacted by changes in testing effort, increases and decreases in testing effort will increase and decrease reproduction number estimates respectively. <br/> <br/> The key files in this dataset are: <ul><li><b>rt.tab</b> - A breakdown of the estimated reproduction number for each location for every date in the calculated range. This includes a statistical breakdown.</li><li><b>summary_table.tab</b> - A summary of the latest effective reprodution number with some related figures describing growth and doubling / halving time</li><li><b>summary_data.tab</b> - a summary of the estimated number of cases with statistical breakdown</li></ul>",
               breakdown = "region",
               country = "United Kingdom"),
             covid_regional_data_identifier = "UK",
             case_modifier = function(cases) {
               cases <- add_uk(cases)
               return(cases) },
             data_args = list(nhsregions = TRUE),
             truncation = 5),
  Region$new(name = "united-kingdom-deaths",
             publication_metadata = PublicationMetadata$new(
               title = "National and Subnational Estimates of the Covid 19 Reproduction Number (R) for the United Kingdom Based on Deaths",
               description = "Identifying changes in the reproduction number, rate of spread, and doubling time during the course of the COVID-19 outbreak whilst accounting for potential biases due to delays in case reporting both nationally and subnationally in the United Kingdom. These results are impacted by changes in testing effort, increases and decreases in testing effort will increase and decrease reproduction number estimates respectively. <br/> <br/> The key files in this dataset are: <ul><li><b>rt.tab</b> - A breakdown of the estimated reproduction number for each location for every date in the calculated range. This includes a statistical breakdown.</li><li><b>summary_table.tab</b> - A summary of the latest effective reprodution number with some related figures describing growth and doubling / halving time</li><li><b>summary_data.tab</b> - a summary of the estimated number of cases with statistical breakdown</li></ul>",
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
               title = "National and Subnational Estimates of the Covid 19 Reproduction Number (R) for the United Kingdom Based on Hospital Admissions",
               description = "Identifying changes in the reproduction number, rate of spread, and doubling time during the course of the COVID-19 outbreak whilst accounting for potential biases due to delays in case reporting both nationally and subnationally in the United Kingdom. These results are impacted by changes in testing effort, increases and decreases in testing effort will increase and decrease reproduction number estimates respectively. <br/> <br/> The key files in this dataset are: <ul><li><b>rt.tab</b> - A breakdown of the estimated reproduction number for each location for every date in the calculated range. This includes a statistical breakdown.</li><li><b>summary_table.tab</b> - A summary of the latest effective reprodution number with some related figures describing growth and doubling / halving time</li><li><b>summary_data.tab</b> - a summary of the estimated number of cases with statistical breakdown</li></ul>",
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
               title = "National and Subnational Estimates of the Covid 19 Reproduction Number (R) for the United States of America Based on Test Results",
               description = "Identifying changes in the reproduction number, rate of spread, and doubling time during the course of the COVID-19 outbreak whilst accounting for potential biases due to delays in case reporting both nationally and subnationally in the United States of America. These results are impacted by changes in testing effort, increases and decreases in testing effort will increase and decrease reproduction number estimates respectively. <br/> <br/> The key files in this dataset are: <ul><li><b>rt.tab</b> - A breakdown of the estimated reproduction number for each location for every date in the calculated range. This includes a statistical breakdown.</li><li><b>summary_table.tab</b> - A summary of the latest effective reprodution number with some related figures describing growth and doubling / halving time</li><li><b>summary_data.tab</b> - a summary of the estimated number of cases with statistical breakdown</li></ul>",
               breakdown = "state",
               country = "United States"),
             covid_regional_data_identifier = "USA",
             region_scale = "State"),
  SuperRegion$new(name = "regional-cases",
                  publication_metadata = PublicationMetadata$new(
                    title = "Continent Summary Reproduction Number (R) Based on Reported Cases",
                    description = "Identifying changes in the reproduction number, rate of spread, and doubling time during the course of the COVID-19 outbreak whilst accounting for potential biases due to delays in case reporting both nationally and subnationally. These results are impacted by changes in testing effort, increases and decreases in testing effort will increase and decrease reproduction number estimates respectively. <br/> <br/> The key files in this dataset are: <ul><li><b>rt.tab</b> - A breakdown of the estimated reproduction number for each location for every date in the calculated range. This includes a statistical breakdown.</li><li><b>summary_table.tab</b> - A summary of the latest effective reprodution number with some related figures describing growth and doubling / halving time</li><li><b>summary_data.tab</b> - a summary of the estimated number of cases with statistical breakdown</li></ul>",
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
                    title = "Continent Summary Reproduction Number (R) Based on Reported Deaths",
                    description = "Identifying changes in the reproduction number, rate of spread, and doubling time during the course of the COVID-19 outbreak whilst accounting for potential biases due to delays in case reporting both nationally and subnationally. These results are impacted by changes in testing effort, increases and decreases in testing effort will increase and decrease reproduction number estimates respectively. <br/> <br/> The key files in this dataset are: <ul><li><b>rt.tab</b> - A breakdown of the estimated reproduction number for each location for every date in the calculated range. This includes a statistical breakdown.</li><li><b>summary_table.tab</b> - A summary of the latest effective reprodution number with some related figures describing growth and doubling / halving time</li><li><b>summary_data.tab</b> - a summary of the estimated number of cases with statistical breakdown</li></ul>",
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
                    title = "National Reproduction Number (R) Based on Reported Cases",
                    description = "Identifying changes in the reproduction number, rate of spread, and doubling time during the course of the COVID-19 outbreak whilst accounting for potential biases due to delays in case reporting both nationally and subnationally. These results are impacted by changes in testing effort, increases and decreases in testing effort will increase and decrease reproduction number estimates respectively. <br/> <br/> The key files in this dataset are: <ul><li><b>rt.tab</b> - A breakdown of the estimated reproduction number for each location for every date in the calculated range. This includes a statistical breakdown.</li><li><b>summary_table.tab</b> - A summary of the latest effective reprodution number with some related figures describing growth and doubling / halving time</li><li><b>summary_data.tab</b> - a summary of the estimated number of cases with statistical breakdown</li></ul>",
                    breakdown = "country"),
                  case_modifier = function(cases) {
                    cases <- cases[, region := country]
                  }),
  SuperRegion$new(name = "deaths",
                  publication_metadata = PublicationMetadata$new(
                    title = "National Reproduction Number (R) Estimates Based on Reported Deaths",
                    description = "Identifying changes in the reproduction number, rate of spread, and doubling time during the course of the COVID-19 outbreak whilst accounting for potential biases due to delays in case reporting both nationally and subnationally. These results are impacted by changes in testing effort, increases and decreases in testing effort will increase and decrease reproduction number estimates respectively. <br/> <br/> The key files in this dataset are: <ul><li><b>rt.tab</b> - A breakdown of the estimated reproduction number for each location for every date in the calculated range. This includes a statistical breakdown.</li><li><b>summary_table.tab</b> - A summary of the latest effective reprodution number with some related figures describing growth and doubling / halving time</li><li><b>summary_data.tab</b> - a summary of the estimated number of cases with statistical breakdown</li></ul>",
                    breakdown = "country"),
                  case_modifier = function(deaths) {
                    deaths <- deaths[country != "Cases_on_an_international_conveyance_Japan"]
                    deaths <- deaths[, cases_new := deaths_new]
                    deaths <- deaths[, region := country]
                  }),
  Region$new(name = "afghanistan",
             publication_metadata = PublicationMetadata$new(
               title = "National and Subnational Estimates of the Covid 19 Reproduction Number (R) for Afghanistan Based on Test Results",
               description = "Identifying changes in the reproduction number, rate of spread, and doubling time during the course of the COVID-19 outbreak whilst accounting for potential biases due to delays in case reporting both nationally and subnationally in Afghanistan. These results are impacted by changes in testing effort, increases and decreases in testing effort will increase and decrease reproduction number estimates respectively. <br/> <br/> The key files in this dataset are: <ul><li><b>rt.tab</b> - A breakdown of the estimated reproduction number for each location for every date in the calculated range. This includes a statistical breakdown.</li><li><b>summary_table.tab</b> - A summary of the latest effective reprodution number with some related figures describing growth and doubling / halving time</li><li><b>summary_data.tab</b> - a summary of the estimated number of cases with statistical breakdown</li></ul>",
               breakdown = "region",
               country = "Afghanistan"),
             case_modifier = function(cases) {
               cases <- cases[!is.na(iso_3166_2)]
               return(cases)
             },
             stable = FALSE),
  Region$new(name = "belgium",
             publication_metadata = PublicationMetadata$new(
               title = "National and Subnational Estimates of the Covid 19 Reproduction Number (R) for Belgium Based on Test Results",
               description = "Identifying changes in the reproduction number, rate of spread, and doubling time during the course of the COVID-19 outbreak whilst accounting for potential biases due to delays in case reporting both nationally and subnationally in Belgium. These results are impacted by changes in testing effort, increases and decreases in testing effort will increase and decrease reproduction number estimates respectively. <br/> <br/> The key files in this dataset are: <ul><li><b>rt.tab</b> - A breakdown of the estimated reproduction number for each location for every date in the calculated range. This includes a statistical breakdown.</li><li><b>summary_table.tab</b> - A summary of the latest effective reprodution number with some related figures describing growth and doubling / halving time</li><li><b>summary_data.tab</b> - a summary of the estimated number of cases with statistical breakdown</li></ul>",
               breakdown = "region",
               country = "Belgium")),
  Region$new(name = "brazil",
             publication_metadata = PublicationMetadata$new(
               title = "National and Subnational Estimates of the Covid 19 Reproduction Number (R) for Brazil Based on Test Results",
               description = "Identifying changes in the reproduction number, rate of spread, and doubling time during the course of the COVID-19 outbreak whilst accounting for potential biases due to delays in case reporting both nationally and subnationally in Brazil. These results are impacted by changes in testing effort, increases and decreases in testing effort will increase and decrease reproduction number estimates respectively. <br/> <br/> The key files in this dataset are: <ul><li><b>rt.tab</b> - A breakdown of the estimated reproduction number for each location for every date in the calculated range. This includes a statistical breakdown.</li><li><b>summary_table.tab</b> - A summary of the latest effective reprodution number with some related figures describing growth and doubling / halving time</li><li><b>summary_data.tab</b> - a summary of the estimated number of cases with statistical breakdown</li></ul>",
               breakdown = "state",
               country = "Brazil")),
  Region$new(name = "canada",
             publication_metadata = PublicationMetadata$new(
               title = "National and Subnational Estimates of the Covid 19 Reproduction Number (R) for Canada Based on Test Results",
               description = "Identifying changes in the reproduction number, rate of spread, and doubling time during the course of the COVID-19 outbreak whilst accounting for potential biases due to delays in case reporting both nationally and subnationally in Canada. These results are impacted by changes in testing effort, increases and decreases in testing effort will increase and decrease reproduction number estimates respectively. <br/> <br/> The key files in this dataset are: <ul><li><b>rt.tab</b> - A breakdown of the estimated reproduction number for each location for every date in the calculated range. This includes a statistical breakdown.</li><li><b>summary_table.tab</b> - A summary of the latest effective reprodution number with some related figures describing growth and doubling / halving time</li><li><b>summary_data.tab</b> - a summary of the estimated number of cases with statistical breakdown</li></ul>",
               breakdown = "state",
               country = "Canada")),
  Region$new(name = "colombia",
             publication_metadata = PublicationMetadata$new(
               title = "National and Subnational Estimates of the Covid 19 Reproduction Number (R) for Colombia Based on Test Results",
               description = "Identifying changes in the reproduction number, rate of spread, and doubling time during the course of the COVID-19 outbreak whilst accounting for potential biases due to delays in case reporting both nationally and subnationally in Colombia. These results are impacted by changes in testing effort, increases and decreases in testing effort will increase and decrease reproduction number estimates respectively. <br/> <br/> The key files in this dataset are: <ul><li><b>rt.tab</b> - A breakdown of the estimated reproduction number for each location for every date in the calculated range. This includes a statistical breakdown.</li><li><b>summary_table.tab</b> - A summary of the latest effective reprodution number with some related figures describing growth and doubling / halving time</li><li><b>summary_data.tab</b> - a summary of the estimated number of cases with statistical breakdown</li></ul>",
               breakdown = "region",
               country = "Colombia")),
  Region$new(name = "germany",
             publication_metadata = PublicationMetadata$new(
               title = "National and Subnational Estimates of the Covid 19 Reproduction Number (R) for Germany Based on Test Results",
               description = "Identifying changes in the reproduction number, rate of spread, and doubling time during the course of the COVID-19 outbreak whilst accounting for potential biases due to delays in case reporting both nationally and subnationally in Germany. These results are impacted by changes in testing effort, increases and decreases in testing effort will increase and decrease reproduction number estimates respectively. <br/> <br/> The key files in this dataset are: <ul><li><b>rt.tab</b> - A breakdown of the estimated reproduction number for each location for every date in the calculated range. This includes a statistical breakdown.</li><li><b>summary_table.tab</b> - A summary of the latest effective reprodution number with some related figures describing growth and doubling / halving time</li><li><b>summary_data.tab</b> - a summary of the estimated number of cases with statistical breakdown</li></ul>",
               breakdown = "state",
               country = "Germany")),
  Region$new(name = "india",
             publication_metadata = PublicationMetadata$new(
               title = "National and Subnational Estimates of the Covid 19 Reproduction Number (R) for India Based on Test Results",
               description = "Identifying changes in the reproduction number, rate of spread, and doubling time during the course of the COVID-19 outbreak whilst accounting for potential biases due to delays in case reporting both nationally and subnationally in India. These results are impacted by changes in testing effort, increases and decreases in testing effort will increase and decrease reproduction number estimates respectively. <br/> <br/> The key files in this dataset are: <ul><li><b>rt.tab</b> - A breakdown of the estimated reproduction number for each location for every date in the calculated range. This includes a statistical breakdown.</li><li><b>summary_table.tab</b> - A summary of the latest effective reprodution number with some related figures describing growth and doubling / halving time</li><li><b>summary_data.tab</b> - a summary of the estimated number of cases with statistical breakdown</li></ul>",
               breakdown = "state",
               country = "India")),
  Region$new(name = "italy",
             publication_metadata = PublicationMetadata$new(
               title = "National and Subnational Estimates of the Covid 19 Reproduction Number (R) for Italy Based on Test Results",
               description = "Identifying changes in the reproduction number, rate of spread, and doubling time during the course of the COVID-19 outbreak whilst accounting for potential biases due to delays in case reporting both nationally and subnationally in Italy. These results are impacted by changes in testing effort, increases and decreases in testing effort will increase and decrease reproduction number estimates respectively. <br/> <br/> The key files in this dataset are: <ul><li><b>rt.tab</b> - A breakdown of the estimated reproduction number for each location for every date in the calculated range. This includes a statistical breakdown.</li><li><b>summary_table.tab</b> - A summary of the latest effective reprodution number with some related figures describing growth and doubling / halving time</li><li><b>summary_data.tab</b> - a summary of the estimated number of cases with statistical breakdown</li></ul>",
               breakdown = "state",
               country = "Italy")),
  Region$new(name = "russia",
             publication_metadata = PublicationMetadata$new(
               title = "National and Subnational Estimates of the Covid 19 Reproduction Number (R) for Russia Based on Test Results",
               description = "Identifying changes in the reproduction number, rate of spread, and doubling time during the course of the COVID-19 outbreak whilst accounting for potential biases due to delays in case reporting both nationally and subnationally in the Russian Federation. These results are impacted by changes in testing effort, increases and decreases in testing effort will increase and decrease reproduction number estimates respectively. <br/> <br/> The key files in this dataset are: <ul><li><b>rt.tab</b> - A breakdown of the estimated reproduction number for each location for every date in the calculated range. This includes a statistical breakdown.</li><li><b>summary_table.tab</b> - A summary of the latest effective reprodution number with some related figures describing growth and doubling / halving time</li><li><b>summary_data.tab</b> - a summary of the estimated number of cases with statistical breakdown</li></ul>",
               breakdown = "state",
               country = "Russian Federation"))
)
