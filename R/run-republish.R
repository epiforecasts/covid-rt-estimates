#' Run Republish
#' Example usage:
#' Rscript R/run-republish.R -w -i "united-states/texas,united-kingdom/*"
#'
#' For more information on execution run Rscript R/run-republish.R --help
#'
#================  INCLUDES ===================#
# load the main run regional updates - it has all the requires and several functions we need
if (!exists("rru_filter_datasets", mode = "function")) source(here::here("R", "run-region-updates.R"))


#=============== Main Functions ====================#

#' Run republish
#' Endpoint to recall the publication of the local results for a particular dataset
#' @param datasets List of AbstractDataset - typically from dataset-list.R
#' @param args List of arguments returned by the cli interface (
#'
run_republish <- function(datasets, args) {
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

  for (dataset in datasets) {
    publish_data(dataset = dataset)
  }

  futile.logger::flog.info("run complete")
}

#============= Ancillary Functions ========================#

#' rrp_cli_interface
#' Define the CLI interface and return the parsed arguments
#' @param args_string String (optional) of command line flags to simulate CLI interface when running from
#' within another program / rstudio
#' @return List of arguments
rrp_cli_interface <- function(args_string = NA) {
  # set up the arguments
  option_list <- list(
    optparse::make_option(c("-v", "--verbose"), action = "store_true", default = FALSE, help = "Print verbose output "),
    optparse::make_option(c("-w", "--werbose"), action = "store_true", default = FALSE, help = "Print v.verbose output "),
    optparse::make_option(c("-q", "--quiet"), action = "store_true", default = FALSE, help = "Print less output "),
    optparse::make_option(c("--log"), type = "character", help = "Specify log file name"),
    optparse::make_option(c("-e", "--exclude"), default = "", type = "character", help = "List of locations to exclude. See include for more details."),
    optparse::make_option(c("-i", "--include"), default = "", type = "character", help = "List of locations to include (excluding all non-specified), comma separated in the format region/subregion or region/*. Case Insensitive. Spaces can be included using quotes - e.g. \"united-states/rhode island, United-States/New York\""),
    optparse::make_option(c("-c", "--collated"), action = "store_true", default = FALSE, help = "process collated derivative rather than raw dataset")
  )
  if (is.character(args_string)) {
    args <- optparse::parse_args(optparse::OptionParser(option_list = option_list), args = args_string)
  }else {
    args <- optparse::parse_args(optparse::OptionParser(option_list = option_list))
  }
  return(args)
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
  args <- rrp_cli_interface()
  setup_log_from_args(args)
  futile.logger::ftry(
    run_republish(
      datasets = DATASETS,
      args = args
    )
  )
}
#==================== Debug function ======================#
example_non_cli_republish_trigger <- function() {
  # list is in the format [flag[, value]?,?]+
  args <- rrp_cli_interface(c("-w", "-i", "canada/*"))
  setup_log_from_args(args)
  futile.logger::ftry(run_republish(datasets = ifelse(args$collated, COLLATED_DERIVATIVES, DATASETS), dargs = args))
}
