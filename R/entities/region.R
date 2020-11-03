#' requirmenets
if (!exists("AbstractDataset", mode = "function")) source(here::here("R/entities", "abstract-dataset.R"))

#' Region class
Region <- R6::R6Class("Region",
                      inherit = AbstractDataset,
                      public = list(covid_regional_data_identifier = NA,
                                    cases_subregion_source = "region_level_1",
                                    data_args = NULL,
                                                          #' @description
                                                          #' Initialise a new `Region` object
                                                          #' @param name String name of dataset
                                                          #' @param publication_metadata PublicationMetadata object defining the publication metadata
                                                          #' @param region_scale string specifying region scale. Currently Region|State|Country
                                                          #' @param case_modifier lambda for modifying cases. must accept cases as a single parameter and return it
                                                          #' @param generation_time String, optional override line list file
                                                          #' @param incubation_period String, optional override line list file
                                                          #' @param reporting_delay String, optional override line list file
                                                          #' @param stable Boolean
                                                          #' @param data_args list for passing to getregionaldata as arguments
                                                          #' @param truncation Integer Number of days to trim off the end of the newest end of the data
                                                          #' @param covid_regional_data_identifier String specifying identification of data on covid region data for when the dataset name != method
                                                          #' @param cases_subregion_source String specifying column to use as location breakdown identifier in dataset
                                                          #' @param folder_name String, Optional, to specify location of output folder.
                                                          #' Used to relocate multiple related datasets into a common folder e.g.
                                                          #' united-kingdom/cases and united-kingdom/deaths - both datasets specify
                                                          #' folder_name = "united-kingdom"
                                                          #' @param dataset_folder_name String specifying the folder within the dataset. Particularly useful in combination of the above to co-locate related datasets
                                                          #' @return a new `Region` object
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