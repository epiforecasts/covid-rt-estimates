#' Adds a UK case count to a dataset usng national level data
add_uk <- function(cases, min_uk) {
  national_cases <- cases[region_level_1 %in% c("England", "Scotland", "Wales", "Northern Ireland")]
  uk_cases <- data.table::copy(national_cases)[, .(cases_new = sum(cases_new, na.rm = TRUE)), by = c("date")]
  uk_cases <- uk_cases[, region_level_1 := "United Kingdom"]

  if (!missing(min_uk)) {
    uk_cases <- uk_cases[date >= as.Date(min_uk)]
  }

  cases <- data.table::rbindlist(list(cases, uk_cases), fill = TRUE, use.names = TRUE)
  return(cases)
}