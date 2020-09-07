#` see SMG.md for documentation

library(R6)

Region <- R6Class("Region", list(
  name = NA,
  covid_regional_data_identifier = NA,
  case_modifier = NA,
  generation_time = NA,
  incubation_period = NA,
  reporting_delay = NA,
  cases_subregion_source = NA,
  region_scale = "Region",
  stable = TRUE,
  initialize = function(name,
                        covid_regional_data_identifier = NA,
                        case_modifier = NA,
                        generation_time = NA,
                        incubation_period = NA,
                        reporting_delay = NA,
                        cases_subregion_source = "region_level_1",
                        region_scale = "Region",
                        stable = TRUE) {
    self$name <- name
    self$covid_regional_data_identifier <- covid_regional_data_identifier
    self$case_modifier <- case_modifier
    self$generation_time <- generation_time
    self$incubation_period <- incubation_period
    self$reporting_delay <- reporting_delay
    self$cases_subregion_source <- cases_subregion_source
    self$region_scale <- region_scale
    self$stable = stable
  }
))
