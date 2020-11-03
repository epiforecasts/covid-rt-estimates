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