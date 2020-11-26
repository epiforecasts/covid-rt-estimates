#' requirements
if (!exists("DATASETS", mode = "function")) source(here::here("R/lists", "dataset-list.R"))
if (!exists("COLLATED_DERIVATIVES", mode = "function")) source(here::here("R/lists", "collated-derivative-list.R"))

#' R6 Class representing a dataset and optionally a sublocation
DatasetLocation <- R6::R6Class("DatasetLocation",
                               list(
                                                                 #' @field dataset String id of dataset
                                 dataset = NA,
                                                                #' @field sublocation String, optional, of sublocation within dataset
                                 sublocation = NULL,
                                                                #' @description
                                                                #' create a new DatasetLocation object
                                                                #' @param dataset String id of dataset
                                                                #' @param sublocation String, Optional of sublocation
                                                                #' @return a new `DatasetLocation` object
                                 initialize = function(dataset, sublocation = NULL) {
                                   if (!dataset %in% names(DATASETS) && !dataset %in% names(COLLATED_DERIVATIVES)) {
                                     stop(paste("Dataset id must be in DATASETS - ", dataset))
                                   }
                                   self$dataset <- dataset
                                   self$sublocation <- sublocation
                                 }
                               )
)