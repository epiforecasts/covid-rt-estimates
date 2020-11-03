source("R/lists/dataset-list.R")
source("R/lists/collated-derivative-list.R")

test_that("no duplicated names in two lists", {
  expect(
    !any(names(DATASETS) %in% names(COLLATED_DERIVATIVES)),
    "Names must be unique in dataset and collated-derivative lists"
  )
})
