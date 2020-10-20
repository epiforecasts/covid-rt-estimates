#' Run Region Updates
#' Example usage:
#' Rscript R/run-region-updates.R -w -i united-states/texas,united-kingdom/*
#' Rscript R/run-region-updates.R -v -e afghanistan/*
#'
# Packages
library(optparse, quietly = TRUE) # bring this in ready for setting up a proper CLI
library(lubridate, quietly = TRUE) # pull in lubridate for the date handling in the summary

# Pull in the definition of the datasets
source(here::here("R", "dataset-list.R"))
# get the onward script
source(here::here("R", "update-regional.R"))

# load utils
source(here::here("R", "utils.R"))

#' Run Regional Updates
#'
run_regional_updates <- function(datasets, args) {
  # validate and load configuration
  if (nchar(args$exclude) > 0 && nchar(args$include) > 0) {
    stop("not possible to both include and exclude regions / subregions")
  }
  excludes <- parse_cludes(args$exclude)
  includes <- parse_cludes(args$include)

  # now really do something
  outcome <- rru_process_locations(datasets, args, excludes, includes)

  if ("united-kingdom-admissions" %in% includes) {
    futile.logger::flog.debug("calling collate estimates for UK")
    collate_estimates(name = "united-kingdom", target = "rt")
  }

  # analysis of outcome
  rru_log_outcome(outcome)
}

rru_cli_interface <- function() {
  # set up the arguments
  option_list <- list(
    make_option(c("-v", "--verbose"), action = "store_true", default = FALSE, help = "Print verbose output "),
    make_option(c("-w", "--werbose"), action = "store_true", default = FALSE, help = "Print v.verbose output "),
    make_option(c("-q", "--quiet"), action = "store_true", default = FALSE, help = "Print less output "),
    make_option(c("--log"), type = "character", help = "Specify log file name"),
    make_option(c("-e", "--exclude"), default = "", type = "character", help = "List of locations to exclude. See include for more details."),
    make_option(c("-i", "--include"), default = "", type = "character", help = "List of locations to include (excluding all non-specified), comma separated in the format region/subregion or region/*. Case Insensitive. Spaces can be included using quotes - e.g. \"united-states/rhode island, United-States/New York\""),
    make_option(c("-u", "--unstable"), action = "store_true", default = FALSE, help = "Include unstable locations"),
    make_option(c("-f", "--force"), action = "store_true", default = FALSE, help = "Run even if data for a region has not been updated since the last run"),
    make_option(c("-t", "--timeout"), type = "integer", default = Inf, help = "Specify the maximum execution time in seconds that each sublocation will be allowed to run for. Note this is not the overall run time."),
    make_option(c("-r", "--refresh"), action = "store_true", default = FALSE, help = "Should estimates be fully refreshed.")
  )

  args <- parse_args(OptionParser(option_list = option_list))
  return(args)
}


rru_process_locations <- function(datasets, args, excludes, includes) {
  outcome <- list()
  for (location in datasets) {
    if (excludes[region == location$name & subregion == "*", .N] > 0) {
      futile.logger::flog.debug("skipping location %s as it is in the exclude/* list", location$name)
      next()
    }
    if (includes[, .N] > 0 && includes[region == location$name, .N] == 0) {
      futile.logger::flog.debug("skipping location %s as it is not in the include list", location$name)
      next()
    }
    if (location$stable || (exists("unstable", args) && args$unstable == TRUE)) {
      start <- Sys.time()
      futile.logger::ftry(
        withCallingHandlers(
          {
          outcome[[location$name]] <-
            update_regional(location,
                        excludes[region == location$name],
                        includes[region == location$name],
                        args$force,
                        args$timeout,
                        refresh = args$refresh)[[1]]
        },
          warning = function(w) {
            futile.logger::flog.warn("%s: %s - %s", location$name, w$mesage, toString(w$call))
            futile.logger::flog.debug(capture.output(rlang::trace_back()))
            rlang::cnd_muffle(w)
          },
          error = function(e) {
            futile.logger::flog.error(capture.output(rlang::trace_back()))
          }
        )
      )
      outcome[[location$name]]$start <- start
    }else {
      futile.logger::flog.debug("skipping location %s as unstable", location$name)
    }
  }

  return(outcome)
}

rru_log_outcome <- function(outcome) {
  # outcome should be:
  # dataset:
  #     subregion : time / inf / null (good, timed out, failed)
  stats_filename <- "runtimes.csv"
  status_filename <- "status.csv"
  futile.logger::flog.info("processing outcome log")
  stats <- loadStatsFile(stats_filename)
  status <- loadStatusFile(status_filename)
  # saveRDS(outcome, "outcome.rds")


  for (dataset_name in names(outcome)) {
    futile.logger::flog.trace("processing results for %s", dataset_name)
    dataset_counts <- list(failures = 0, timeouts = 0, successes = 0)
    for (subregion in names(outcome[[dataset_name]])) {
      if (subregion %in% c("start", "max_data_date", "oldest_results")) {
        next
      }
      existing <-
        stats[stats$dataset == dataset_name &
                stats$subregion == subregion,]

      if (is.null(outcome[[dataset_name]][[subregion]])) {
        runtime <- -1
        dataset_counts$failures <- dataset_counts$failures + 1
      } else if (is.finite(outcome[[dataset_name]][[subregion]])) {
        runtime <- outcome[[dataset_name]][[subregion]]
        dataset_counts$successes <- dataset_counts$successes + 1
      }else {
        runtime <- 999999
        dataset_counts$timeouts <- dataset_counts$timeouts + 1
      }

      if (nrow(existing) == 0) {
        futile.logger::flog.trace("no record exists for %s / %s so create a new one", dataset_name, subregion)
        stats <- dplyr::rows_insert(
          stats,
          data.frame(
            dataset = dataset_name,
            subregion = subregion,
            start_date = outcome[[dataset_name]]$start,
            runtime = runtime
          ),
          by = c("dataset", "subregion")
        )
      } else {
        futile.logger::flog.trace("record exists for %s / %s so advance prior counters and update", dataset_name, subregion)
        existing$runtime_4 <- existing$runtime_3
        existing$start_date_4 <- existing$start_date_3
        existing$runtime_3 <- existing$runtime_2
        existing$start_date_3 <- existing$start_date_2
        existing$runtime_2 <- existing$runtime_1
        existing$start_date_2 <- existing$start_date_1
        existing$runtime_1 <- existing$runtime
        existing$start_date_1 <- existing$start_date
        existing$start_date <- outcome[[dataset_name]]$start
        existing$runtime <- runtime
        stats <- dplyr::rows_upsert(stats, existing, by = c("dataset", "subregion"))
      }
    }

    status_row <-
      status[status$dataset == dataset_name,]

    # calculate dataset status
    dataset_completed <- FALSE
    dataset_processed <- FALSE
    if (dataset_counts$failures == 0 &&
      dataset_counts$timeouts == 0 &&
      dataset_counts$successes == 0) {
      futile.logger::flog.trace("dataset %s had no data to process", dataset_name)
      dataset_status <- "No Data To Process"
    }else if (dataset_counts$failures == 0 && dataset_counts$timeouts == 0) {
      futile.logger::flog.trace("dataset %s has a complete results set", dataset_name)
      dataset_status <- "Complete"
      dataset_completed <- TRUE
      dataset_processed <- TRUE
    }else if (dataset_counts$successes > 0) {
      futile.logger::flog.trace("dataset %s has a complete results set", dataset_name)
      dataset_status <- "Partial"
      dataset_processed <- TRUE
    }else if (dataset_counts$failures == 0) {
      futile.logger::flog.trace("dataset %s has a completely timed out", dataset_name)
      dataset_status <- "Timed Out"
    }else {
      futile.logger::flog.trace("dataset %s had an error", dataset_name)
      dataset_status <- "Error"
    }
    if (nrow(status_row) == 0) {
      futile.logger::flog.trace("no status record exists for %s so create a new one", dataset_name)
      status <- dplyr::rows_insert(
        status,
        data.frame(
          dataset = dataset_name,
          last_attempt = outcome[[dataset_name]]$start,
          last_attempt_status = dataset_status,
          latest_results = dplyr::if_else(dataset_processed, outcome[[dataset_name]]$start, NULL),
          latest_results_status = ifelse(dataset_processed, dataset_status, NULL),
          latest_results_data_up_to = dplyr::if_else(dataset_processed, outcome[[dataset_name]]$max_data_date, NULL),
          latest_results_successful_regions = ifelse(dataset_processed, dataset_counts$successes, 0),
          latest_results_timing_out_regions = ifelse(dataset_processed, dataset_counts$timeouts, 0),
          latest_results_failing_regions = ifelse(dataset_processed, dataset_counts$failures, 0),
          oldest_region_results = outcome[[dataset_name]]$oldest_results
        ),
        by = c("dataset")
      )
    } else {
      futile.logger::flog.trace("status record exists for %s", dataset_name)
      status_row$dataset <- dataset_name
      status_row$last_attempt <- outcome[[dataset_name]]$start
      status_row$last_attempt_status <- dataset_status
      status_row$latest_results <- dplyr::if_else(dataset_processed, outcome[[dataset_name]]$start, status_row$latest_results)
      status_row$latest_results_status <- ifelse(dataset_processed, dataset_status, status_row$latest_results_status)
      status_row$latest_results_data_up_to <- dplyr::if_else(dataset_processed, outcome[[dataset_name]]$max_data_date, status_row$latest_results_data_up_to)
      status_row$latest_results_successful_regions <- ifelse(dataset_processed, dataset_counts$successes, status_row$latest_results_successful_regions)
      status_row$latest_results_timing_out_regions <- ifelse(dataset_processed, dataset_counts$timeouts, status_row$latest_results_timing_out_regions)
      status_row$latest_results_failing_regions <- ifelse(dataset_processed, dataset_counts$failures, status_row$latest_results_failing_regions)
      status_row$oldest_region_results <- outcome[[dataset_name]]$oldest_results
      status <- dplyr::rows_upsert(status, status_row, by = c("dataset"))
    }
  }
  futile.logger::flog.trace("writing file")
  write.csv(stats[order(stats$dataset, stats$subregion),], file = stats_filename, row.names = FALSE)
  write.csv(status[order(status$dataset),], file = status_filename, row.names = FALSE)
}

loadStatsFile <- function(filename) {
  if (file.exists(filename)) {
    futile.logger::flog.trace("loading the existing file")
    stats <- read.csv(file = filename,
                      colClasses = c("dataset" = "character",
                                     "subregion" = "character",
                                     "start_date" = "character",
                                     "runtime" = "double",
                                     "start_date_1" = "character",
                                     "runtime_1" = "double",
                                     "start_date_2" = "character",
                                     "runtime_2" = "double",
                                     "start_date_3" = "character",
                                     "runtime_3" = "double",
                                     "start_date_4" = "character",
                                     "runtime_4" = "double"))
    futile.logger::flog.trace("reformatting the dates back to being dates")
    stats$start_date <- as.POSIXct(strptime(stats$start_date, "%Y-%m-%d %H:%M:%OS"), tz = "UTC")
    stats$start_date_1 <- as.POSIXct(strptime(stats$start_date_1, "%Y-%m-%d %H:%M:%OS"), tz = "UTC")
    stats$start_date_2 <- as.POSIXct(strptime(stats$start_date_2, "%Y-%m-%d %H:%M:%OS"), tz = "UTC")
    stats$start_date_3 <- as.POSIXct(strptime(stats$start_date_3, "%Y-%m-%d %H:%M:%OS"), tz = "UTC")
    stats$start_date_4 <- as.POSIXct(strptime(stats$start_date_4, "%Y-%m-%d %H:%M:%OS"), tz = "UTC")
  } else {
    futile.logger::flog.trace("no existing file, creating a blank table")
    stats <- data.frame(
      dataset = character(),
      subregion = character(),
      start_date = POSIXct(),
      runtime = double(),
      start_date_1 = POSIXct(),
      runtime_1 = double(),
      start_date_2 = POSIXct(),
      runtime_2 = double(),
      start_date_3 = POSIXct(),
      runtime_3 = double(),
      start_date_4 = POSIXct(),
      runtime_4 = double()
    )
  }
  return(stats)
}
loadStatusFile <- function(filename) {
  if (file.exists(filename)) {
    futile.logger::flog.trace("loading the existing status file")
    status <- read.csv(file = filename,
                       colClasses = c("dataset" = "character",
                                      "last_attempt" = "character",
                                      "last_attempt_status" = "character",
                                      "latest_results" = "character",
                                      "latest_results_status" = "character",
                                      "latest_results_data_up_to" = "character",
                                      "latest_results_successful_regions" = "integer",
                                      "latest_results_timing_out_regions" = "integer",
                                      "latest_results_failing_regions" = "integer",
                                      "oldest_region_results" = "character"
                       ))
    futile.logger::flog.trace("reformatting the dates back to being dates")
    status$last_attempt <- as.POSIXct(strptime(status$last_attempt, "%Y-%m-%d %H:%M:%OS"), tz = "UTC")
    status$latest_results <- as.POSIXct(strptime(status$latest_results, "%Y-%m-%d %H:%M:%OS"), tz = "UTC")
    status$oldest_region_results <- strptime(status$oldest_region_results, "%Y-%m-%d %H:%M:%OS")
    status$latest_results_data_up_to <- as.Date(status$latest_results_data_up_to, format = "%Y-%m-%d")
  } else {
    futile.logger::flog.trace("no existing status file, creating a blank table")
    status <- data.frame(
      dataset = character(),
      last_attempt = POSIXct(),
      last_attempt_status = character(),
      latest_results = POSIXct(),
      latest_results_status = character(),
      latest_results_data_up_to = Date(),
      latest_results_successful_regions = integer(),
      latest_results_timing_out_regions = integer(),
      latest_results_failing_regions = integer(),
      oldest_region_results = POSIXct()
    )
  }
  return(status)
}

# only execute if this is the root, passing in datasets from dataset-list.R and the args from the cli interface
# this bit handles the outer logging wrapping and top level error handling
if (sys.nframe() == 0) {
  args <- rru_cli_interface()
  setup_log_from_args(args)
  futile.logger::ftry(run_regional_updates(datasets = datasets, args = args))
}
