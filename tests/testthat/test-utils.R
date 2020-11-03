source(here::here("R/utils.R"))

test_that("no duplicated names in two lists", {
  expect(
    !any(names(DATASETS) %in% names(COLLATED_DERIVATIVES)),
    "Names must be unique in dataset and collated-derivative lists"
  )
})
