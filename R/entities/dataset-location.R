#' requirements

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
                                   self$dataset <- dataset
                                   self$sublocation <- sublocation
                                 }
                               )
)