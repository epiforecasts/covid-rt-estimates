#' Requires
if (!exists("DatasetLocation", mode = "function")) source(here::here("R/entities/dataset-location.R"))


#' Set up logging from optparse arguments
setup_log_from_args <- function(args) {
  file <- ifelse(exists("log", args), args$log, "info.log")
  futile.logger::flog.appender(futile.logger::appender.tee(file))
  futile.logger::flog.layout(futile.logger::layout.format("~t ~l ~m"))
  if (args$quiet) {
    futile.logger::flog.threshold(futile.logger::WARN)
  }else if (args$werbose) {
    futile.logger::flog.threshold(futile.logger::TRACE)
  }else if (args$verbose) {
    futile.logger::flog.threshold(futile.logger::DEBUG)
  }else {
    futile.logger::flog.threshold(futile.logger::INFO)
  }
  return(invisible(NULL))
}

#' Set up parallel processing on all available cores
setup_future <- function(jobs, min_cores_per_worker = 2) {
  if (!interactive()) {
    ## If running as a script enable this
    options(future.fork.enable = TRUE)
  }

  workers <- min(ceiling(future::availableCores() / min_cores_per_worker), jobs)
  cores_per_worker <- max(1, round(future::availableCores() / workers, 0))

  futile.logger::flog.info("Using %s workers with %s cores per worker",
                           workers, cores_per_worker)


  future::plan(list(future::tweak(future::multiprocess, workers = workers, gc = TRUE, earlySignal = TRUE),
                    future::tweak(future::multiprocess, workers = cores_per_worker)))
  futile.logger::flog.debug("Checking the cores available - %s cores and %s jobs. Using %s workers",
                            future::availableCores(),
                            jobs,
                            min(future::availableCores(), jobs))

  return(cores_per_worker)
}


#' Check data to see if updated since last run
check_for_update <- function(cases, last_run) {
  current_max_date <- max(cases$date, na.rm = TRUE)

  if (file.exists(last_run)) {
    futile.logger::flog.trace("last_run file (%s) exists, loading.", last_run)
    last_run_date <- readRDS(last_run)

    if (current_max_date <= last_run_date) {
      futile.logger::flog.info("Data has not been updated since last run. If wanting to run again then remove %s", last_run)
      futile.logger::flog.debug("Max date in data - %s, last run date from file - %s",
                                format(current_max_date, "%Y-%m-%d"),
                                format(last_run_date, "%Y-%m-%d"))
      return(FALSE)
    }
  }
  futile.logger::flog.debug("New data to process")
  saveRDS(current_max_date, last_run)

  return(TRUE)
}

#' Clean regional data
clean_regional_data <- function(cases, truncation = 3, data_window = 12) {
  futile.logger::flog.trace("starting to clean the cases")
  cases <- cases[, .(region, date = as.Date(date), confirm = cases_new)]
  cases <- cases[date <= Sys.Date()]
  cases <- cases[, .SD[date <= (max(date, na.rm = TRUE) - lubridate::days(truncation))], by = region]
  if (!is.infinite(data_window)) {
    cases <- cases[, .SD[date >= (max(date) - lubridate::weeks(data_window))], by = region]
  }
  cases <- cases[!is.na(confirm)]
  data.table::setorder(cases, date)
  return(cases)
}

#' trim
#' remove leading and trailing whitespace
#' @param x string
#' @return string
trim <- function(x) {
  gsub("^\\s+|\\s+$", "", x)
}

#' parse 'cludes
#' @param cludes string of in/excludes
#' @return data.frame of regions / subregions
parse_cludes <- function(cludes) {
  nrows <- length(regmatches(cludes, gregexpr("/", cludes))[[1]])
  if (nrows == 0) return(list())
  clude_list <- vector(mode = "list", length = nrows)
  locs <- strsplit(cludes, ",")
  for (loc in locs) {
    parts <- strsplit(loc, "/")
  }
  i <- 1
  for (region in parts) {
    sub <- trim(region[2])
    if (sub == "*") {
      clude_list[[i]] <- DatasetLocation$new(dataset = tolower(trim(region[1])))
    }else {
      clude_list[[i]] <- DatasetLocation$new(dataset = tolower(trim(region[1])),
                                             sublocation = sub)
    }
    i <- i + 1
  }
  return(clude_list)
}

#' case insensitive version of the in function
#' @param x string
#' @param y string
#' @return boolean
`%in_ci%` <- function(x, y) {
  tolower(x) %in% tolower(y)
}

#' Collate estimates from different estimates in same sub-regional folder
#' DEPRECATED

collate_estimates <- function(name, target = "rt") {

  # Get locations of summary csv
  sources <- as.list(paste0(list.files(here::here("subnational", name), full.names = TRUE),
                            "/summary/", target, ".csv"))
  names(sources) <- list.files(here::here("subnational", name))

  # Read and bind
  sources <- sources[!grepl("collated", names(sources))]
  df <- lapply(sources, data.table::fread)
  df <- data.table::rbindlist(df, idcol = "source")
  df <- df[type %in% "estimate"][, type := NULL]

  # Check a collated file exists
  if (!dir.exists(here::here("subnational", name, "collated", target))) {
    dir.create(here::here("subnational", name, "collated", target), recursive = TRUE)
  }

  # Save back to main folder
  data.table::fwrite(df, here::here("subnational", name, "collated", target, paste0('summary_', Sys.Date(), ".csv")))
  data.table::fwrite(df, here::here("subnational", name, "collated", target, 'summary_latest.csv'))

  return(invisible(NULL))

}

#'generate clean cases
#' produce a neat data set for a single region
#' @param number_of_days - how far back in time should we go
#' @param regions List Character region names
#' @param peak_cases What's the last value for number of new cases
#' @param days_since_peak Which day is the peak (0=today, 20 = 20 days ago)
generate_clean_cases <- function(
  number_of_days = 90,
  regions = list("my_test_region"),
  peak_cases = 2000,
  days_since_peak = 0
) {
  today <- Sys.Date()
  df <- data.frame(
    "date" = lubridate::Date(),
    "region" = character(),
    "cases_new" = numeric(),
    "cases_total" = numeric(),
    "deaths_new" = numeric(),
    "deaths_total" = numeric()
  )
  # peak_day = days since peak
  pre_peak <- number_of_days - days_since_peak
  larger_side <- max(pre_peak, days_since_peak)
  day_size <- pi / larger_side

  for (region in regions) {
    for (n in 1:pre_peak) {
      val <- (cos(0 - n * day_size) + 1) / 2 * peak_cases
      df <- rbind(df, data.frame(date = today - days_since_peak - n,
                                 region = region,
                                 cases_new = round(val),
                                 cases_total = 500,
                                 deaths_new = 1,
                                 deaths_total = 100))
    }
    for (n in 0:days_since_peak) {
      val <- (cos(n * day_size) + 1) / 2 * peak_cases
      df <- rbind(df, data.frame(date = today - days_since_peak + n,
                                 region = region,
                                 cases_new = round(val),
                                 cases_total = 500,
                                 deaths_new = 1,
                                 deaths_total = 100))
    }
  }
  return(data.table::as.data.table(df))
}
