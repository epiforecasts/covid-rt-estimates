#' Run Region Updates
#' Example usage:
#' Rscript R/run-region-updates.R -w -i united-states/texas,united-kingdom/*
#' Rscript R/run-region-updates.R -v -e afghanistan/*
#'
# Packages
library(optparse, quietly = TRUE) # bring this in ready for setting up a proper CLI
library(rlang, quietly = TRUE) # error handling

# Pull in the definition of the regions
source(here::here("R", "region-list.R"))
# get the onward script
source(here::here("R", "update-regional.R"))
# load utils
source(here::here("R", "utils.R"))

#' Run Regional Updates
#'
run_regional_updates <- function(regions, args) {
  # validate and load configuration
  if (nchar(args$exclude) > 0 && nchar(args$include) > 0) {
    stop("not possible to both include and exclude regions / subregions")
  }
  excludes <- parse_cludes(args$exclude)
  includes <- parse_cludes(args$include)

  # now really do something
  rru_process_locations(regions, args, excludes, includes)
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
    make_option(c("-f", "--force"), action = "store_true", default = FALSE, help = "Run even if data for a region has not been updated since the last run")
  )

  args <- parse_args(OptionParser(option_list = option_list))
  return(args)
}


rru_process_locations <- function(regions, args, excludes, includes) {
  for (location in regions) {
    if (excludes[region == location$name & subregion == "*", .N] > 0) {
      futile.logger::flog.debug("skipping location %s as it is in the exclude/* list", location$name)
      next()
    }
    if (includes[, .N] > 0 && includes[region == location$name, .N] == 0) {
      futile.logger::flog.debug("skipping location %s as it is not in the include list", location$name)
      next()
    }
    if (location$stable || (exists("unstable", args) && args$unstable == TRUE)) {
      tryCatch(withCallingHandlers({
                                     update_regional(location,
                                                     excludes[region == location$name],
                                                     includes[region == location$name],
                                                     args$force)
                                   },
                                   warning = function(w) {
                                     futile.logger::flog.warn("%s: %s - %s", location$name, w$mesage, toString(w$call))
                                     cnd_muffle(w)
                                   }),
               error = function(e) {
                 futile.logger::flog.error("%s: %s - %s", location$name, e$message, toString(e$call))
                 futile.logger::flog.error(capture.output(trace_back()))
               }
      )
    }else {
      futile.logger::flog.debug("skipping location %s as unstable", location$name)
    }
  }
}

# only execute if this is the root, passing in regions from region-list.R and the args from the cli interface
# this bit handles the outer logging wrapping and top level error handling
if (sys.nframe() == 0) {
  args <- rru_cli_interface()
  setup_log_from_args(args)
  tryCatch(withCallingHandlers(run_regional_updates(regions = regions, args = args),
                               warning = function(w) {
                                 futile.logger::flog.warn(w)
                                 cnd_muffle(w)
                               }),
           error = function(e) {
             futile.logger::flog.error(e)
             futile.logger::flog.error(capture.output(trace_back()))
           })
}