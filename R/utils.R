#' Set up logging to file
setup_log <- function(threshold = "INFO", file = "info.log") {
  futile.logger::flog.threshold(threshold)

  futile.logger::flog.appender(futile.logger::appender.tee(file))

  return(invisible(NULL))
}
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
setup_future <- function(jobs, min_cores_per_worker = 4) {
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
clean_regional_data <- function(cases, truncation = 3) {
  futile.logger::flog.trace("starting to clean the cases")
  cases <- cases[, .(region, date = as.Date(date), confirm = cases_new)]
  cases <- cases[date <= Sys.Date()]
  cases <- cases[, .SD[date <= (max(date, na.rm = TRUE) - lubridate::days(truncation))], by = region]
  cases <- cases[, .SD[date >= (max(date) - lubridate::weeks(12))], by = region]
  cases <- cases[!is.na(confirm)]
  data.table::setorder(cases, date)

  return(cases)
}

#' Regional EpiNow with settings
regional_epinow_with_settings <- function(reported_cases, generation_time, delays,
                                          target_dir, summary_dir, no_cores, max_execution_time = Inf,
                                          region_scale = "Region", region_summary = TRUE) {
  futile.logger::flog.trace("calling regional_epinow")
  out <- regional_epinow(reported_cases = reported_cases,
                  generation_time = generation_time,
                  delays = delays, non_zero_points = 14,
                  horizon = 14, burn_in = 14,
                  samples = 2000, warmup = 500,
                  fixed_future_rt = TRUE,
                  cores = no_cores, chains = ifelse(no_cores <= 2, 2, no_cores),
                  target_folder = target_dir,
                  summary_dir = summary_dir,
                  region_scale = region_scale,
                  all_regions = region_summary,
                  return_estimates = FALSE, verbose = FALSE, max_execution_time = max_execution_time, return_timings = TRUE)
  futile.logger::flog.debug("resetting future plan to sequential")
  future::plan("sequential")
  return(invisible(out))
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
  clude_list <- vector(mode = "list", length = length(cludes))
  locs <- strsplit(cludes, ",")
  for (loc in locs) {
    parts <- strsplit(loc, "/")
  }
  i <- 1
  for (region in parts) {
    sub <- trim(region[2])
    clude_list[[i]] <- DatasetLocation$new(dataset = tolower(trim(region[1])),
                                           sublocation = ifelse(sub == "*", NULL, sub))
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


