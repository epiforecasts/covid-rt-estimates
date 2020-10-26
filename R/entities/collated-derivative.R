#' requirements
if (!exists("DatasetLocation", mode = "function")) source(here::here("R/entities", "dataset-location.R"))
if (!exists("PublicationMetadata", mode = "function")) source(here::here("R/entities", "publication-metadata.R"))

CollatedDerivative <- R6::R6Class(
  "CollatedDerivative",
  list(
    name = NA,
    locations = list(),
    publication_metadata = NA,
    incremental = FALSE,
      #' @description
      #' @param name Name of this collated derivative
      #' @param locations List of locations to include
      #' @param publication_metadata PublicationMetadata object containing the publication metadata
      #' for the derivative
      #' @param incremental Boolean flag - calculate collated derivative after each individual
      #' location change or only on completion of set - typically 1 update / day or multiple. Default
      #' behaviour is non-incremental (one update / overall processing run)
      #' @return Instance of `CollatedDerivative` class
    initialize = function(
      name,
      locations,
      publication_metadata,
      incremental = FALSE
    ) {
      if (!PublicationMetadata$classname %in% class(publication_metadata)) {
        stop("publication_metadata must be an instance of PublicationMetadata")
      }
      if (!is.list(locations)) {
        stop("locations must be a list")
      }
      if (length(locations) == 0) {
        stop("at least 1 location must be included in the locations list")
      }
      lapply(locations, function(location) {
        if (!DatasetLocation$classname %in% class(location)) {
          stop("locations must all be instances of DatasetLocation")
        }
      })
      self$name <- name
      self$locations <- locations
      self$publication_metadata <- publication_metadata
      self$incremental <- incremental
    }
  )
)