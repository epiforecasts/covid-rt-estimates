#' requires
#' grab the pure form of DATASETS as reference
if (!exists("DATASETS", mode = "function")) source(here::here("R/lists", "dataset-list.R"))
if (!exists("%in_ci%", mode = "function")) source(here::here("R", "utils.R"))
if (!exists("publish_data", mode = "function")) source(here::here("R", "publish-data.R"))

#' collate_derivative
#' @param derivative `CollatedDerivative` object to calculate
collate_derivative <- function(derivative) {
  datasets <- DATASETS[names(DATASETS) %in_ci% lapply(derivative$locations, function(dsl) { dsl$dataset })]
  for (target in derivative$targets) {
    futile.logger::flog.debug("process target file %s", target)
    sources <- cd_prime_sources(datasets, target)
    # collate the data - currently dataset only, #todo: subfiltering
    df <- cd_read_and_bind_sources(sources)

    if (!dir.exists(here::here(derivative$summary_dir))) {
      dir.create(here::here(derivative$summary_dir), recursive = TRUE)
    }
    futile.logger::flog.trace("writing collated file to disk")
    data.table::fwrite(df, here::here(derivative$summary_dir, paste0(target, '.csv')))
    # tidy up
    rm(df)
  }

  futile.logger::flog.info("publishing derivative %s", derivative$name)
  publish_data(derivative)
}

#' cd_prime_sources
#' Calculate list of source files to process for a given target in a list of datasets
#' @param datasets List of `DatasetLocation`
#' @param target String csv filename to collate
#' @return List of files to collate
cd_prime_sources <- function(datasets, target) {
  futile.logger::flog.trace("process dataset files for target file")
  # prime a sources list
  sources <- vector(mode = "list", length = length(datasets))
  names(sources) <- names(datasets)
  # setup dataverse config if needed
  if (exists("DATAVERSE_SERVER") && exists("DATAVERSE_KEY")) {
    Sys.setenv("DATAVERSE_SERVER" = DATAVERSE_SERVER)
    Sys.setenv("DATAVERSE_KEY" = DATAVERSE_KEY)
  }
  for (dataset_name in names(datasets)) {
    file <- NULL
    if (exists("DATAVERSE_SERVER") && exists("DATAVERSE_KEY")) {
      futile.logger::flog.trace("checking for %s in dataset %s on dataverse", target, dataset_name)
      full_dataset <- check_for_existing_id(dataset_name)
      if (is.list(full_dataset)) {
        futile.logger::flog.trace("dataset found, checking for files")
        files <- na.omit(full_dataset$files[full_dataset$files$originalFileName == paste0(target, ".csv"),])
        if (nrow(files) == 1) {
          tmpfile <- tempfile()
          futile.logger::flog.debug("%s file found for dataset %s - downloading to %s", target, dataset_name, tmpfile)
          writeBin(dataverse::get_file(files$id, format = "original"), tmpfile)
          file <- tmpfile
        }
      }
    }

    ## if there's no luck retrieving the file check local disk
    if (is.null(file)) {
      futile.logger::flog.trace("no file found on dataverse so checking disk")
      test_path <- here::here(datasets[[dataset_name]]$summary_dir, paste0(target, ".csv"))
      if (file.exists(test_path)) {
        file <- test_path
      }
    }

    # check if it's got one
    if (is.null(file)) stop(paste0("unable to find file for dataset ", dataset_name, " file ", target, ".csv"))

    # if it has add it to the list
    sources[[dataset_name]] <- file
  }

  return(sources)
}

#' read_and_bind_sources
#' @param sources list of csv source files
#' @return dataframe
cd_read_and_bind_sources <- function(sources) {
  sources <- sources[!grepl("collated", names(sources))]
  df <- lapply(sources, data.table::fread)
  df <- data.table::rbindlist(df, idcol = "source")
  df <- df[type %in% "estimate"][, type := NULL]
  return(df)
}
