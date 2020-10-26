#' requirements
if (!exists("PublicationMetadata", mode = "function")) source(here::here("R/entities", "publication-metadata.R"))

#' Abstract Dataset
AbstractDataset <- R6::R6Class("AbstractDataset",
                               list(
                                 name = NA,
                                 publication_metadata = NA,
                                 summary_dir = NA,
                                 case_modifier = NA,
                                 generation_time = NA,
                                 incubation_period = NA,
                                 reporting_delay = NA,
                                 region_scale = NA,
                                 truncation = NA,
                                 stable = TRUE,
                                 target_folder = NA,
                                 data_args = NULL,
                                 initialize = function(
                                   name,
                                   publication_metadata,
                                   region_scale,
                                   case_modifier = NA,
                                   generation_time = NA,
                                   incubation_period = NA,
                                   reporting_delay = NA,
                                   stable = TRUE,
                                   data_args = NULL,
                                   truncation = 3
                                 ) {

                                   if (!PublicationMetadata$classname %in% class(publication_metadata)) {
                                     stop("publication_metadata must be an instance of PublicationMetadata")
                                   }
                                   self$name <- name
                                   self$publication_metadata <- publication_metadata
                                   self$case_modifier <- case_modifier
                                   self$generation_time <- generation_time
                                   self$incubation_period <- incubation_period
                                   self$reporting_delay <- reporting_delay
                                   self$stable <- stable
                                   self$data_args <- data_args
                                   self$region_scale <- region_scale
                                   self$truncation <- truncation
                                 }
                               ))