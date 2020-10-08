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

safe_update <- purrr::safely(update_regional)

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
      # tryCatch(withCallingHandlers({
      outcome[[location$name]] <-
        safe_update(location,
                    excludes[region == location$name],
                    includes[region == location$name],
                    args$force,
                    args$timeout,
                    refresh = args$refresh)[[1]]
      #                                                          },
      #                                                          warning = function(w) {
      #                                                            futile.logger::flog.warn("%s: %s - %s", location$name, w$mesage, toString(w$call))
      #                                                            rlang::cnd_muffle(w)
      #                                                          },
      #                                                          error = function(e) {
      #                                                            futile.logger::flog.error(capture.output(rlang::trace_back()))
      #                                                          }),
      #                                      error = function(e) {
      #                                        futile.logger::flog.error("%s: %s - %s", location$name, e$message, toString(e$call))
      #                                      }
      # )
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
  filename <- "runtimes.csv"
  futile.logger::flog.info("processing outcome log")
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
    stats$start_date <- strptime(stats$start_date, "%Y-%m-%d %H:%M:%OS")
    stats$start_date_1 <- strptime(stats$start_date_1, "%Y-%m-%d %H:%M:%OS")
    stats$start_date_2 <- strptime(stats$start_date_2, "%Y-%m-%d %H:%M:%OS")
    stats$start_date_3 <- strptime(stats$start_date_3, "%Y-%m-%d %H:%M:%OS")
    stats$start_date_4 <- strptime(stats$start_date_4, "%Y-%m-%d %H:%M:%OS")
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


  for (dataset_name in names(outcome)) {
    futile.logger::flog.trace("processing results for %s", dataset_name)
    for (subregion in names(outcome[[dataset_name]])) {
      if (subregion == "start") {
        next
      }
      existing <-
        stats[stats$dataset == dataset_name &
                stats$subregion == subregion,]
      if (nrow(existing) == 0) {
        futile.logger::flog.trace("no record exists for %s / %s so create a new one", dataset_name, subregion)
        stats <- dplyr::rows_insert(
          stats,
          data.frame(
            dataset = dataset_name,
            subregion = subregion,
            start_date = outcome[[dataset_name]]$start,
            runtime = ifelse(is.null(outcome[[dataset_name]][[subregion]]),
                             -1,
                             ifelse(is.finite(outcome[[dataset_name]][[subregion]]),
                                    outcome[[dataset_name]][[subregion]],
                                    999999)
            )
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
        existing$runtime <- ifelse(is.null(outcome[[dataset_name]][[subregion]]),
                                   -1,
                                   ifelse(is.finite(outcome[[dataset_name]][[subregion]]),
                                          outcome[[dataset_name]][[subregion]],
                                          999999)
        )
        stats <-
          dplyr::rows_upsert(stats, existing, by = c("dataset", "subregion"))
      }
    }
  }
  futile.logger::flog.trace("writing file")
  write.csv(stats, file = filename, row.names = FALSE)
}

# only execute if this is the root, passing in datasets from dataset-list.R and the args from the cli interface
# this bit handles the outer logging wrapping and top level error handling
if (sys.nframe() == 0) {
  args <- rru_cli_interface()
  setup_log_from_args(args)
  # tryCatch(withCallingHandlers(
  run_regional_updates(datasets = datasets, args = args)
  # ,
  #                            warning = function(w) {
  #                              futile.logger::flog.warn(w)
  #                              rlang::cnd_muffle(w)
  #                            },
  #                            error = function(e) {
  #                              futile.logger::flog.error(capture.output(rlang::trace_back()))
  #                            }),
  #        error = function(e) {
  #          futile.logger::flog.error(e)
  #        })
}
