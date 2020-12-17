#' requirmenets
if (!exists("AbstractDataset", mode = "function")) source(here::here("R/entities", "abstract-dataset.R"))

#' SuperRegion class. So called because its bigger than a region and calling it "global" seemed like a programmers idea of a bad joke...
SuperRegion <- R6::R6Class("SuperRegion",
                           inherit = AbstractDataset,
                           public = list(covid_national_data_identifier = "who",

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
                                                               #' @param covid_national_data_identifier String specifying identification of data on covid region data
                                                               #' @param folder_name String, Optional, to specify location of output folder.
                                                               #' Used to relocate multiple related datasets into a common folder e.g.
                                                               #' united-kingdom/cases and united-kingdom/deaths - both datasets specify
                                                               #' folder_name = "united-kingdom"
                                                               #' @return a new `SuperRegion` object
                                         initialize = function(...,
                                                               covid_national_data_identifier = "ecdc",
                                                               region_scale = "Country",
                                                               folder_name = NA) {
                                           super$initialize(..., region_scale)
                                           self$covid_national_data_identifier <- covid_national_data_identifier
                                           highest_folder <- ifelse(region_scale == "Country", "national/", "region/")
                                           middle_folder <- ifelse(is.na(folder_name), self$name, folder_name)
                                           tail_target_folder <- ifelse(region_scale == "Country", "/national", "/region")
                                           self$target_folder <- paste0(highest_folder, middle_folder, tail_target_folder)
                                           self$summary_dir <- paste0(highest_folder, middle_folder, "/summary")
                                         }))
