#' Requirements
if (!exists("CollatedDerivative", mode = "function")) source(here::here("R", "entities/collated-derivative.R"))
if (!exists("DatasetLocation", mode = "function")) source(here::here("R", "entities/dataset-location.R"))
if (!exists("PublicationMetadata", mode = "function")) source(here::here("R/entities", "publication-metadata.R"))

#' List of all collated derivatives
COLLATED_DERIVATIVES <- list(
  "united-kingdom-collated" = CollatedDerivative$new(
    name = "united-kingdom-collated",
    locations = list(
      DatasetLocation$new("united-kingdom"),
      DatasetLocation$new("united-kingdom-deaths"),
      DatasetLocation$new("united-kingdom-admissions")
    ),
    publication_metadata = PublicationMetadata$new(
      title = "Collated Results of the National and Subnational Estimates of the Covid 19 Reproduction Number (R) for the United Kingdom Based on Tests, Hospital Admissions and Deaths",
      description = "Identifying changes in the reproduction number, rate of spread, and doubling time during the course of the COVID-19 outbreak whilst accounting for potential biases due to delays in case reporting both nationally and subnationally in the United Kingdom. These results are impacted by changes in testing effort, increases and decreases in testing effort will increase and decrease reproduction number estimates respectively. This dataset brings together the calculations based on Test, Hospital Admissions and Deaths to allow easier cross-analysis.",
      breakdown = "region",
      country = "United Kingdom"
    )
  )
)