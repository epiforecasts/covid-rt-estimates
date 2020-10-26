#' requirmenets
if (!exists("AbstractDataset", mode = "function")) source(here::here("R/entities", "abstract-dataset.R"))

# This seemed a better name than global...
SuperRegion <- R6::R6Class("SuperRegion",
                           inherit = AbstractDataset,
                           public = list(covid_national_data_identifier = "ecdc",
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