#` see SMG.md for documentation

library(R6)

AbstractDataset <- R6Class("AbstractDataset", list(
  name = NA,
  case_modifier = NA,
  generation_time = NA,
  incubation_period = NA,
  reporting_delay = NA,
  region_scale = NA,
  stable = TRUE,
  target_folder = NA,
  summary_dir = NA
))
# This seemed a better name than global...
SuperRegion <- R6Class("SuperRegion",
                       inherit = AbstractDataset,
                       public = list(covid_national_data_identifier = "ecdc",
                                     initialize = function(name,
                                                           covid_national_data_identifier = "ecdc",
                                                           case_modifier = NA,
                                                           generation_time = NA,
                                                           incubation_period = NA,
                                                           reporting_delay = NA,
                                                           region_scale = "Country",
                                                           stable = TRUE,
                                                           folder_name = NA) {
                                       self$name <- name
                                       self$covid_national_data_identifier <- covid_national_data_identifier
                                       self$case_modifier <- case_modifier
                                       self$generation_time <- generation_time
                                       self$incubation_period <- incubation_period
                                       self$reporting_delay <- reporting_delay
                                       self$region_scale <- region_scale
                                       self$stable <- stable
                                       highest_folder <- ifelse(region_scale == "Country", "national/", "region/")
                                       middle_folder <- ifelse(is.na(folder_name), name, folder_name)
                                       tail_target_folder <- ifelse(region_scale == "Country", "/national", "/region")
                                       self$target_folder <- paste0(highest_folder, middle_folder, "/national")
                                       self$summary_dir <- paste0(highest_folder, middle_folder, "/summary")
                                     }))

Region <- R6Class("Region",
                  inherit = AbstractDataset,
                  public = list(covid_regional_data_identifier = NA,
                                cases_subregion_source = "region_level_1",
                                data_args = NULL,
                                initialize = function(name,
                                                      covid_regional_data_identifier = NA,
                                                      case_modifier = NA,
                                                      generation_time = NA,
                                                      incubation_period = NA,
                                                      reporting_delay = NA,
                                                      cases_subregion_source = "region_level_1",
                                                      data_args = NULL,
                                                      region_scale = "Region",
                                                      stable = TRUE,
                                                      folder_name = NA,
                                                      dataset_folder_name = "cases") {
                                  self$name <- name
                                  self$covid_regional_data_identifier <- covid_regional_data_identifier
                                  self$data_args <- data_args
                                  self$case_modifier <- case_modifier
                                  self$generation_time <- generation_time
                                  self$incubation_period <- incubation_period
                                  self$reporting_delay <- reporting_delay
                                  self$cases_subregion_source <- cases_subregion_source
                                  self$region_scale <- region_scale
                                  self$stable <- stable
                                  middle_folder <- ifelse(is.na(folder_name), name, folder_name)
                                  self$target_folder <- paste0("subnational/", middle_folder, "/", dataset_folder_name, "/national")
                                  self$summary_dir <- paste0("subnational/", middle_folder, "/", dataset_folder_name, "/summary")
                                }))

