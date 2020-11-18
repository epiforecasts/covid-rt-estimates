#' Run Region Updates
#' Example usage:
#' Rscript R/run-region-updates.R -w -i united-states/texas,united-kingdom/*
#' Rscript R/run-region-updates.R -v -e afghanistan/*
#'
#' For more information on execution run Rscript R/run-region-updates.R --help
#'
#' This file is concerned with the high level control of the datasets, sequencing of processing and
#' logging of run outcomes. The dataset processing itself starts to happen in update-regional.R
#' which in turn calls on to EpiNow to do the real meat of the processing.
#'
#================  INCLUDES ===================#
# Packages
suppressPackageStartupMessages(library(optparse, quietly = TRUE)) # bring this in ready for setting up a proper CLI
suppressPackageStartupMessages(library(lubridate, quietly = TRUE)) # pull in lubridate for the date handling in the summary

# Pull in the definition of the datasets
if (!exists("DATASETS", mode = "function")) source(here::here("R/lists", "dataset-list.R"))
if (!exists("COLLATED_DERIVATIVES", mode = "function")) source(here::here("R/lists", "collated-derivative-list.R"))
# get the script for processing each dataset (this one starts to deal with the model data rather
# than just configuration )
if (!exists("update_regional", mode = "function")) source(here::here("R", "update-regional.R"))
if (!exists("collate_derivative", mode = "function")) source(here::here("R", "collate-derivative.R"))

# load utils
if (!exists("setup_log_from_args", mode = "function")) source(here::here("R", "utils.R"))
# load config (optional)
if (!exists("DATAVERSE_KEY", mode = "function")
  & file.exists(here::here("data/runtime", "config.R"))) source(here::here("data/runtime", "config.R"))
# load utils
if (!exists("publish_data", mode = "function")) source(here::here("R", "publish-data.R"))


#=============== Main Functions ====================#

#' Run Regional Updates
#' Main function for process - this is probably what you want to call if you are loading a custom
#' dataset or modified args
#' Sequences the high level blocks of the process
#' @param datasets List of AbstractDataset - typically from dataset-list.R
#' @param datasets List of CollatedDerivative  - typically from collated-derivative-list.R
#' @param args List of arguments returned by the cli interface (
#'
run_regional_updates <- function(datasets, derivatives, args) {
  futile.logger::flog.trace("run_regional_updates")
  # validate and load configuration
  if (nchar(args$exclude) > 0 && nchar(args$include) > 0) {
    stop("not possible to both include and exclude regions / subregions")
  }
  futile.logger::flog.trace("process includes")
  excludes <- parse_cludes(args$exclude)
  includes <- parse_cludes(args$include)
  futile.logger::flog.trace("filter datasets")
  datasets <- rru_filter_datasets(datasets, excludes, includes)

  # now really do something
  futile.logger::flog.trace("process locations")
  outcome <- rru_process_locations(datasets, args, excludes, includes)

  if ("united-kingdom-admissions" %in% includes) { # DEPRECATED
    futile.logger::flog.debug("calling collate estimates for UK")
    collate_estimates(name = "united-kingdom", target = "rt")
  }
  saveRDS(outcome, "outcome.RDS")
  # analysis of outcome
  futile.logger::flog.trace("analise results")
  rru_log_outcome(outcome)

  # process derivatives
  futile.logger::flog.trace("process derivative datasets")
  rru_process_derivatives(derivatives, datasets)

  futile.logger::flog.info("run complete")
}

#' rru_process_locations
#' handles the include / exclude functionality and unpacking the list of datasets.
#' calls on to update_regional, adding additional logging with improved context.
#' @param datasets List of AbstractDataset
#' @param args List of arguments from cli tool
#' @param excludes List of strings, processed from the args
#' @param includes List of strings, processed from the args
#' @returns List of results for each dataset
rru_process_locations <- function(datasets, args, excludes, includes) {
  outcome <- list()
  for (location in datasets) {
    if (location$stable || (exists("unstable", args) && args$unstable == TRUE)) {
      start <- Sys.time()
      futile.logger::ftry(
        withCallingHandlers(
          {
          outcome[[location$name]] <-
            update_regional(location,
                            excludes,
                            includes,
                            args$force,
                            args$timeout,
                            refresh = args$refresh)
          saveRDS(outcome, paste0(location$name, "_raw_outcome.rds"))
        },
          warning = function(w) {
            futile.logger::flog.warn(w)
            futile.logger::flog.debug(capture.output(rlang::trace_back()))
            saveRDS(w, "last_warning.rds")
            futile.logger::flog.warn("%s: %s", location$name, w)
            rlang::cnd_muffle(w)
          },
          error = function(e) {
            futile.logger::flog.error(capture.output(rlang::trace_back()))
            futile.logger::flog.error(e)
          }
        )
      )
      outcome[[location$name]]$start <- start
      if (!args$suppress) {
        futile.logger::ftry(publish_data(location))
      }
    }else {
      futile.logger::flog.debug("skipping location %s as unstable", location$name)
    }
  }

  return(outcome)
}

#' rru_log_outcome
#' Processes the outcome returned by rru_process_locations to assorted log files
#' This is handling runtime status information, not actual results values
#' @param outcome List produced by rru_process_locations
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

    if (Reduce("+", dataset_counts) == 0) {
      futile.logger::flog.error("No subregions recorded in outcome for %s", dataset_name)
      next
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

#' rru_process_derivatives
#' work out what processing needs to happen for collated derivatives
#' @param derivatives List of `CollatedDerivative`
#' @param datasets List of `AbstractDataset`
rru_process_derivatives <- function(derivatives, datasets) {
  for (derivative in derivatives) {
    if (
      (derivative$incremental & any(names(datasets) %in_ci% lapply(derivative$locations, function(dsl) { dsl$dataset })))
        |
        (!derivative$incremental & tail(derivative$locations, n = 1)[[1]]$dataset %in_ci% names(datasets))
    ) {
      futile.logger::flog.info("calculating derivative for %s", derivative$name)
      collate_derivative(derivative)
    }
  }
}
#============= Ancillary Functions ========================#

#' rru_cli_interface
#' Define the CLI interface and return the parsed arguments
#' @param args_string String (optional) of command line flags to simulate CLI interface when running from
#' within another program / rstudio
#' @return List of arguments
rru_cli_interface <- function(args_string = NA) {
  # set up the arguments
  option_list <- list(
    optparse::make_option(c("-v", "--verbose"), action = "store_true", default = FALSE, help = "Print verbose output "),
    optparse::make_option(c("-w", "--werbose"), action = "store_true", default = FALSE, help = "Print v.verbose output "),
    optparse::make_option(c("-q", "--quiet"), action = "store_true", default = FALSE, help = "Print less output "),
    optparse::make_option(c("--log"), type = "character", help = "Specify log file name"),
    optparse::make_option(c("-e", "--exclude"), default = "", type = "character", help = "List of locations to exclude. See include for more details."),
    optparse::make_option(c("-i", "--include"), default = "", type = "character", help = "List of locations to include (excluding all non-specified), comma separated in the format region/subregion or region/*. Case Insensitive. Spaces can be included using quotes - e.g. \"united-states/rhode island, United-States/New York\""),
    optparse::make_option(c("-u", "--unstable"), action = "store_true", default = FALSE, help = "Include unstable locations"),
    optparse::make_option(c("-f", "--force"), action = "store_true", default = FALSE, help = "Run even if data for a region has not been updated since the last run"),
    optparse::make_option(c("-t", "--timeout"), type = "integer", default = 999999, help = "Specify the maximum execution time in seconds that each sublocation will be allowed to run for. Note this is not the overall run time."),
    optparse::make_option(c("-r", "--refresh"), action = "store_true", default = FALSE, help = "Should estimates be fully refreshed."),
    optparse::make_option(c("-s", "--suppress"), action = "store_true", default = FALSE, help = "Suppress publication of results")
  )
  if (is.character(args_string)) {
    args <- optparse::parse_args(optparse::OptionParser(option_list = option_list), args = args_string)
  }else {
    args <- optparse::parse_args(optparse::OptionParser(option_list = option_list))
  }
  return(args)
}

#' rru_filter_datasets
#' Slice out only the top level datasets we want to process
#' @param datasets List of AbstractDataset
#' @param excludes List of strings, processed from the args
#' @param includes List of strings, processed from the args
#' @return List of AbstractDataset or empty list
rru_filter_datasets <- function(datasets, excludes, includes) {
  if (length(excludes) > 0) {
    for (exclude in excludes) {
      # if it applies to the whole dataset knock it out
      if (is.null(exclude$sublocation)) {
        datasets[[exclude$dataset]] <- NULL
      }
    }
  }
  if (length(includes) > 0) { # if there are includes filter to only those needed
    datasets <- datasets[names(datasets) %in_ci% lapply(includes, function(dsl) { dsl$dataset })]
  }
  return(datasets)
}
#' loadStatsFile
#' @param filename String filename to load stats from (csv)
#' @return data.frame of correctly formatted data - either loaded from the filename or blank if
#' filename is missing
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
      start_date = lubridate::POSIXct(),
      runtime = double(),
      start_date_1 = lubridate::POSIXct(),
      runtime_1 = double(),
      start_date_2 = lubridate::POSIXct(),
      runtime_2 = double(),
      start_date_3 = lubridate::POSIXct(),
      runtime_3 = double(),
      start_date_4 = lubridate::POSIXct(),
      runtime_4 = double()
    )
  }
  return(stats)
}

#' loadStatusFile
#' Clone of loadstatsfile but with different file structure
#' @param filename String filename to load status from (csv)
#' @return data.frame of correctly formatted data - either loaded from the filename or blank if
#' filename is missing
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
      last_attempt = lubridate::POSIXct(),
      last_attempt_status = character(),
      latest_results = lubridate::POSIXct(),
      latest_results_status = character(),
      latest_results_data_up_to = lubridate::Date(),
      latest_results_successful_regions = integer(),
      latest_results_timing_out_regions = integer(),
      latest_results_failing_regions = integer(),
      oldest_region_results = lubridate::POSIXct()
    )
  }
  return(status)
}

#================ Main trigger ================#
# only executes if this is the root of the application, making it source the file in Rstudio and
# extend / modify it for custom dataset processing. Search "python __main__" for a lot of info about
# why this is helpful in python (the same concepts are true in R but it's less written about)
#
# This does minimal functionality - it only configures bits that are core to the functioning
# of the code, not actually processing data
# - triggers the cli interface
# - configures logging
# - Puts a top level log catch around the main function
if (sys.nframe() == 0) {
  args <- rru_cli_interface()
  setup_log_from_args(args)
  futile.logger::ftry(
    run_regional_updates(
      datasets = DATASETS,
      derivatives = COLLATED_DERIVATIVES,
      args = args
    )
  )
}
#==================== Debug function ======================#
example_non_cli_trigger <- function() {
  # list is in the format [flag[, value]?,?]+
  args <- rru_cli_interface(c("-w", "-i", "canada/*", "-t", "1800", "-s"))
  setup_log_from_args(args)
  futile.logger::ftry(run_regional_updates(datasets = datasets, args = args))
}
