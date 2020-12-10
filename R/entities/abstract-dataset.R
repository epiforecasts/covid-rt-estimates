#' requirements
if (!exists("PublicationMetadata", mode = "function")) source(here::here("R/entities", "publication-metadata.R"))

#' Abstract Dataset class
AbstractDataset <- R6::R6Class("AbstractDataset",
                               list(
                                 #' @field name of dataset
                                 name = NA,
                                                                #' @field publication_metadata `PublicationMetadata` object
                                 publication_metadata = NA,
                                                                #' @field summary_dir location of summary directory
                                 summary_dir = NA,
                                                                #' @field data optional function for downloading data. If not supplied will default to using `covidregionaldata`
                                 data = NA,             
                                                                #' @field case_modifier lambda for modifying cases. must accept cases as a single parameter and return it
                                 case_modifier = NA,
                                                                #' @field generation_time optional override line lists
                                 generation_time = NA,
                                                                #' @field incubation_period optional override line lists
                                 incubation_period = NA,
                                                                #' @field reporting_delay optional override line lists
                                 reporting_delay = NA,
                                                                #' @field region_scale string specifying region scale. Currently Region|State|Country
                                 region_scale = NA,
                                                                #' @field truncation Number of days to truncate from the end of the data
                                 truncation = 0,
                                                                #' @field data_window Number of weeks to use when estimating (referenced from most recent date)
                                 data_window = 12,
                                                                #' @field stable Boolean indicating if dataset is stable
                                 stable = TRUE,
                                                                #' @field target_folder for individual location results
                                 target_folder = NA,
                                                                #' @field data_args for passing to getregionaldata
                                 data_args = NULL,
                                                                #' @field regional_epinow_opts List of arguments to pass to regional_epinow
                                 regional_epinow_opts = NULL,    
                                 
                                                                #' @description
                                                                #' Create an abstract dataset - you should only do this through a child extension
                                                                #' @param name String name of dataset
                                                                #' @param publication_metadata PublicationMetadata object defining the publication metadata
                                                                #' @param region_scale string specifying region scale. Currently Region|State|Country
                                                                #' @param data Function for downloading data
                                                                #' @param case_modifier lambda for modifying cases. must accept cases as a single parameter and return it
                                                                #' @param generation_time String, optional override line list file
                                                                #' @param incubation_period String, optional override line list file
                                                                #' @param reporting_delay String, optional override line list file
                                                                #' @param stable Boolean
                                                                #' @param data_window Number of weeks to use when estimating (referenced from most recent date)
                                                                #' @param data_args list for passing to getregionaldata as arguments
                                                                #' @param truncation Integer Number of days to trim off the end of the newest end of the data
                                                                #' @param regional_epinow_opts List of options to be passed to regional_epinow
                                                                #' @return A new `AbstractDataset` Object
                                 initialize = function(
                                   name,
                                   publication_metadata,
                                   region_scale,
                                   data = NA,
                                   case_modifier = NA,
                                   generation_time = NA,
                                   incubation_period = NA,
                                   reporting_delay = NA,
                                   stable = TRUE,
                                   data_args = NULL,
                                   truncation = 0,
                                   data_window = 12,
                                   regional_epinow_opts = list(rt = EpiNow2::rt_opts(prior = list(mean = 1, sd = 0.2)),
                                                               stan = EpiNow2::stan_opts(samples = 4000, warmup = 400, cores = 1,
                                                               chains = 4, control = list(adapt_delta = 0.95),
                                                               future = FALSE),
                                                               output = c("plots", "latest"),
                                                               non_zero_points = 14, horizon = 14, logs = NULL)
                                 ) {

                                   if (!PublicationMetadata$classname %in% class(publication_metadata)) {
                                     stop("publication_metadata must be an instance of PublicationMetadata")
                                   }
                                   self$name <- name
                                   self$publication_metadata <- publication_metadata
                                   self$data <- data
                                   self$case_modifier <- case_modifier
                                   self$generation_time <- generation_time
                                   self$incubation_period <- incubation_period
                                   self$reporting_delay <- reporting_delay
                                   self$stable <- stable
                                   self$data_args <- data_args
                                   self$region_scale <- region_scale
                                   self$truncation <- truncation
                                   self$regional_epinow_opts <- regional_epinow_opts
                                   self$data_window <- data_window
                                 }
                               ))
