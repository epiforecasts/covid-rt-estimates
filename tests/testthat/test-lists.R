source(here::here("R/lists/dataset-list.R"))
source(here::here("R/lists/collated-derivative-list.R"))

test_that("no duplicated names in two lists", {
  expect(
    !any(names(DATASETS) %in% names(COLLATED_DERIVATIVES)),
    "Names must be unique in dataset and collated-derivative lists"
  )
})

test_that("list names match key", {
  for (key in names(DATASETS)) {
    expect_equal(key, DATASETS[[key]]$name)
  }
  for (key in names(COLLATED_DERIVATIVES)) {
    expect_equal(key, COLLATED_DERIVATIVES[[key]]$name)
  }
})
