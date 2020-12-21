#' Requirements
if (!exists("Region", mode = "function")) source(here::here("R", "entities/region.R"))
if (!exists("SuperRegion", mode = "function")) source(here::here("R", "entities/super-region.R"))
if (!exists("add_uk", mode = "function")) source(here::here("R", "case-manipulation-utils.R"))

#' List of datasets (Regions / Super regions
#' Order is defined as follows:
#' 1. Priority
#' 2. ABC
#'
DATASETS <- list(
  "united-kingdom-local" = Region$new(name = "united-kingdom-local", # leaving this as the default UK for historic purposes
                                publication_metadata = PublicationMetadata$new(
                                  title = "Local Estimates of the Covid 19 Reproduction Number (R) for the United Kingdom Based on Test Results",
                                  description = "Identifying changes in the reproduction number, rate of spread, and doubling time during the course of the COVID-19 outbreak whilst accounting for potential biases due to delays in case reporting at the local authority level in the United Kingdom. These results are impacted by changes in testing effort, increases and decreases in testing effort will increase and decrease reproduction number estimates respectively.",
                                  breakdown = "authority",
                                  country = "United Kingdom"),
		                cases_subregion_source = "region_level_2",
                                covid_regional_data_identifier = "UK",
                                data_args = list(include_level_2_regions = TRUE),
                                truncation = 3)
)
