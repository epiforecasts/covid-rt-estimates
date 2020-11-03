source(here::here("R/utils.R"))

test_that(
  "confirm trim trims",
  {
    test_pairs <- list(
      c("a ", "a"),
      c("  a  ", "a"),
      c(" a  ", "a"),
      c(" a
    ", "a"),
      c("leave me", "leave me"),
      c(" leave me ", "leave me")
    )
    for (pair in test_pairs) {
      expect_equal(pair[[2]], trim(pair[[1]]))
    }
  }
)

test_that(
  "case insensitive in works, including list in list and value in list",
  {
    test_pairs <- list(
      list(c("a", "b", "C"), c("A", "b", "c")),
      list(list("a", "b", "C"), list("A", "b", "c")),
      list("C", list("A", "b", "c"))
    )
    for (pairs in test_pairs) {
      expect_true(all(pairs[[1]] %in_ci% pairs[[2]]))
    }
  }
)

test_that(
  "log threshold is correct",
  {
    test_data <- list(
      list(
        list(quiet = FALSE, werbose = FALSE, verbose = FALSE),
        futile.logger::INFO,
        "Should default to info"
      ),
      list(
        list(quiet = FALSE, werbose = FALSE, verbose = TRUE),
        futile.logger::DEBUG,
        "Debug mode activated"
      ),
      list(
        list(quiet = FALSE, werbose = TRUE, verbose = TRUE),
        futile.logger::TRACE,
        "Werbose overrules verbose"
      ),
      list(
        list(quiet = TRUE, werbose = TRUE, verbose = TRUE),
        futile.logger::WARN,
        "Quiet trumps all"
      )
    )
    for (test in test_data) {
      setup_log_from_args(test[[1]])
      expect_equal(futile.logger::flog.threshold(), names(test[[2]]), info = test[[3]])
    }
  }
)



test_that(
  "clean_regional_data cleans",
  {
    test_data <- generate_clean_cases()
    result <- clean_regional_data(test_data)
    expect_equal(nrow(result), 85) #12 weeks + 1 day
    expect_equal(max(result$date), Sys.Date() - 3) # default trim
    expect_equal(max(result$confirm), max(test_data$cases_new)) # check the col rename
    result <- clean_regional_data(test_data, 10)
    expect_equal(nrow(result), 85) #12 weeks + 1 day
    expect_equal(max(result$date), Sys.Date() - 10) # custom trim
  }
)

test_that(
  "parse_cludes unpacks correctly",
  {
    result <- parse_cludes("canada/*,belgium/unknown , canada/nova scotia, united-states/Alabama")
    expect_equal(length(result), 4)
    expect_true(all(lapply(result, function(dl) { dl$dataset }) %in_ci% list("canada", "belgium", "united-states")))
    expect_true(all(lapply(result, function(dl) { dl$sublocation }) %in_ci% list("unknown", "nova scotia", NULL, "alabama")))

  }
)