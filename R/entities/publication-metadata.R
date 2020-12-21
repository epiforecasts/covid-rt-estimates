#' requirements
if (!exists("DATAVERSE_COUNTRIES", mode = "function")) source(here::here("R/lists", "dataverse-countries.R"))

#' PublicationMetadata class
PublicationMetadata <- R6::R6Class("PublicationMetadata",
                                   public = list(
                                                                        #' @field title String publication title for the dataset
                                     title = "",
                                                                        #' @field description String long description for the dataset
                                     description = "",
                                                                        #' @field breakdown_unit String one from ("continent", "country", "region", "state") to specify lowest location type
                                     breakdown_unit = "",
                                                                        #' @field country String - optional country name (from dataverse-countries) if all the data is within a single country
                                     country = NA,
                                                                        #' @description
                                                                        #' Initialize a new instance of PublicationMetadata
                                                                        #' @param title String publication title for the dataset
                                                                        #' @param description String long description for the dataset
                                                                        #' @param breakdown_unit String one from ("continent", "country", "region", "state") to specify lowest location type
                                                                        #' @param country String - optional country name (from dataverse-countries) if all the data is within a single country
                                     initialize = function(title,
                                                           description,
                                                           breakdown_unit,
                                                           country = NA) {
                                       self$title <- title
                                       self$description <- description
                                       if (breakdown_unit %in% c("continent", "country", "region", "state")) {
                                         self$breakdown_unit <- breakdown_unit
                                       }else {
                                         stop(paste("invalid breakdown unit", breakdown_unit))
                                       }
                                       if (is.na(country)) {
                                         if (breakdown_unit %in% c("region", "state")) {
                                           stop("country must be specified if breakdown is below country level (region / state)")
                                         }
                                       }else {
                                         if (!country %in% DATAVERSE_COUNTRIES) {
                                           stop("Invalid country - ", country, " - must be one of ", DATAVERSE_COUNTRIES)
                                         }
                                       }
                                       self$country <- country
                                     }
                                   ))

