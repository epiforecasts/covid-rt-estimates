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
    sources <- lapply(datasets, function(dataset) { here::here(dataset$summary_dir, paste0(target, ".csv")) })
    names(sources) <- names(datasets)
    # collate the data - currently dataset only, #todo: subfiltering
    df <- cd_read_and_bind_sources(sources)

    if (!dir.exists(here::here(derivative$summary_dir))) {
      dir.create(here::here(derivative$summary_dir), recursive = TRUE)
    }

    data.table::fwrite(df, here::here(derivative$summary_dir, paste0(target, '.csv')))

    rm(df)

    publish_data(derivative)
  }
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
