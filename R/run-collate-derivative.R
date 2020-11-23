#============= INCLUDES =================#
# load utils
if (!exists("setup_log_from_args", mode = "function")) source(here::here("R", "utils.R"))
# load master list of available collated derivatives
if (!exists("COLLATED_DERIVATIVES", mode = "function")) source(here::here("R/lists", "collated-derivative-list.R"))
# load the actual script
if (!exists("collate_derivative", mode = "function")) source(here::here("R", "collate-derivative.R"))


run_collate_derivative <- function(derivatives, args) {
  #validate
  if (args$derivative %in_ci% names(derivatives)) {
    #run
    collate_derivative(derivatives[[tolower(args$derivative)]], !args$suppress)
  } else {
    futile.logger::flog.error("%s is not a valid collated derivative", args$derivative)
  }
}

rcd_cli_interface <- function(args_string = NULL) {
  # set up the arguments
  option_list <- list(
    optparse::make_option(c("-d", "--derivative"), default = "", type = "character", help = "A single collated derivative name to process"),
    optparse::make_option(c("-v", "--verbose"), action = "store_true", default = FALSE, help = "Print verbose output "),
    optparse::make_option(c("-w", "--werbose"), action = "store_true", default = FALSE, help = "Print v.verbose output "),
    optparse::make_option(c("-q", "--quiet"), action = "store_true", default = FALSE, help = "Print less output "),
    optparse::make_option(c("--log"), type = "character", help = "Specify log file name"),
    optparse::make_option(c("-s", "--suppress"), action = "store_true", default = FALSE, help = "Suppress publication of results")
  )
  if (is.character(args_string)) {
    args <- optparse::parse_args(optparse::OptionParser(option_list = option_list), args = args_string)
  }else {
    args <- optparse::parse_args(optparse::OptionParser(option_list = option_list))
  }
  return(args)
}

if (sys.nframe() == 0) {
  args <- rcd_cli_interface()
  setup_log_from_args(args)
  futile.logger::ftry(
    run_collate_derivative(
      derivatives = COLLATED_DERIVATIVES,
      args = args
    )
  )
}
