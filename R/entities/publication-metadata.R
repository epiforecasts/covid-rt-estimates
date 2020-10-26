# requirements
if (!exists("DATAVERSE_COUNTRIES", mode = "function")) source(here::here("R/enumerations", "dataverse-countries.R"))

PublicationMetadata <- R6::R6Class("PublicationMetadata",
                                   public = list(
                                     title = "",
                                     description = "",
                                     breakdown_unit = "",
                                     country = NA,
                                     initialize = function(title,
                                                           description, breakdown_unit, country = NA) {
                                       self$title <- title
                                       self$description <- description
                                       if (breakdown_unit %in% c("continent", "country", "region", "state")) {
                                         self$breakdown_unit <- breakdown_unit
                                       }else {
                                         stop("invalid breakdown unit")
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

