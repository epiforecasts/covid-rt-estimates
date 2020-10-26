#' requirmenets
if (!exists("AbstractDataset", mode = "function")) source(here::here("R/entities", "abstract-dataset.R"))

Region <- R6::R6Class("Region",
                      inherit = AbstractDataset,
                      public = list(covid_regional_data_identifier = NA,
                                    cases_subregion_source = "region_level_1",
                                    data_args = NULL,
                                    initialize = function(...,
                                                          covid_regional_data_identifier = NA,
                                                          cases_subregion_source = "region_level_1",
                                                          region_scale = "Region",
                                                          folder_name = NA,
                                                          dataset_folder_name = "cases") {

                                      super$initialize(..., region_scale)
                                      self$covid_regional_data_identifier <- covid_regional_data_identifier
                                      self$cases_subregion_source <- cases_subregion_source
                                      middle_folder <- ifelse(is.na(folder_name), self$name, folder_name)
                                      self$target_folder <- paste0("subnational/", middle_folder, "/", dataset_folder_name, "/national")
                                      self$summary_dir <- paste0("subnational/", middle_folder, "/", dataset_folder_name, "/summary")
                                    }))