#' Publish a dataset to a dataverse
#' @param dataset AbstractDataset to publish or CollatedDerivative (they both have the required interface)
#' @param files Boolean indicator as to if files should be uploaded. Helpful for test purposes
#' @param production_date Date specifying when the data is for. Gets used as the production date in the metadata, defaults to today.
publish_data <- function(dataset, files = TRUE, production_date = NA) {
  if (exists("DATAVERSE_SERVER") && exists("DATAVERSE_KEY")) {
    Sys.setenv("DATAVERSE_SERVER" = DATAVERSE_SERVER)
    Sys.setenv("DATAVERSE_KEY" = DATAVERSE_KEY)
    if (require(dataverse)) {
      library(desc) # this is used to get the author data from the DESCRIPTION file
      full_dataset <- check_for_existing_id(dataset$name)
      if (is.list(full_dataset)) {
        futile.logger::flog.debug("%s: dataverse exists so just update", dataset$name)
        dataset_id <- full_dataset$datasetId
        updated_metadata <- generate_dataset_metadata(dataset, production_date)$datasetVersion
        update_dataset(dataset = dataset_id, body = updated_metadata)
        # loop  through the summary dir adding all the files
        if (files) {
          existing_files <- full_dataset$files
          # exclude directories
          for (file in dir(dataset$summary_dir, pattern = ".*\\..*")) {
            file_full_path <- paste0(dataset$summary_dir, "/", file)
            existing_file_id <- list()
            if (length(existing_files) > 0) {
              # if there are files to look at filter on either filename or original filename == the file, selecting just the ID and MD5 checksum cols
              existing_file_ids <- unique(existing_files[existing_files$filename == file | existing_files$originalFileName == file, c("id", "md5")])
              # strip na's
              existing_file_ids <- existing_file_ids[!is.na(existing_file_ids)]
              # are there any?
              if (length(existing_file_ids) > 0) {
                # unpackage for later use
                existing_file_id <- as.numeric(existing_file_ids[[1]])
                existing_file_checksum <- existing_file_ids[[2]]
                # if there's a checksum check it!
                if (length(existing_file_checksum) > 0) {
                  if (existing_file_checksum == tools::md5sum(file_full_path)) {
                    futile.logger::flog.debug("file is unchanged, don't re-upload %s", file_full_path)
                    next
                  }
                }
              }
            }
            if (length(existing_file_id) > 0) {
              # allow silent failures - it rejects non-changing updates.
              futile.logger::flog.trace("replacing file %s", file_full_path)
              try(futile.logger::ftry(update_dataset_file(file = file_full_path, dataset = dataset_id, id = existing_file_id)), silent = TRUE)
            }else {
              futile.logger::flog.trace("uploading file %s", file_full_path)
              try(futile.logger::ftry(add_dataset_file(file = file_full_path, dataset = dataset_id)), silent = TRUE)
            }
          }
        }
      }else {
        futile.logger::flog.info("%s: dataverse does not exist so creating a new one", dataset$name)
        metadata <- generate_dataset_metadata(dataset, production_date)
        ds <- create_dataset(dataverse = DATAVERSE_VERSEID, body = metadata)
        dataset_id <- ds$data$id
        # loop  through the summary dir adding all the files
        if (files) {
          for (file in dir(dataset$summary_dir, pattern = ".*\\..*")) {
            futile.logger::flog.trace("submitting file %s", paste0(dataset$summary_dir, "/", file))
            try(futile.logger::ftry(add_dataset_file(paste0(dataset$summary_dir, "/", file), dataset_id)), silent = TRUE)
          }
        }
      }
      futile.logger::flog.info("%s: publishing", dataset$name)
      Sys.sleep(30) # sleep for 30 seconds to give dataverse a chance to catch up on the files...
      try(futile.logger::ftry(publish_dataset(dataset_id, minor = FALSE)), silent = TRUE)
    }else {
      futile.logger::flog.debug("Dataverse not enabled, no attempt to publish")
    }
  }else {
    futile.logger::flog.debug("No dataverse credentials loaded, no attempt to publish")
  }
  return()
}
# try to find an existing dataset using the dataset_name as an id in the keywords
check_for_existing_id <- function(dataset_name) {
  # load existing
  existing_datasets <-
    dataverse_contents(DATAVERSE_VERSEID, key = DATAVERSE_KEY, server = DATAVERSE_SERVER)
  existing <- NA
  for (existing_dataset in existing_datasets) {
    # deaccessed datasets are not accessible anymore - they can be skipped over but you can't test
    # for them from the data returned in the contents. Best I can find is they just 404 when you
    # load them. :(
    full_dataset <- tryCatch(get_dataset(existing_dataset$id),
                             error = function(c) {
                               NA
                             }
    )
    if (!is.list(full_dataset)) {
      next
    }
    # for some reason the metadata keywords are inside the citation bcollate_derivative(COLLATED_DERIVATIVES[[1]])lock... go figure
    # loop over them looking for the keyword value and then check if it's the name of the dataset.
    for (metadata in full_dataset$metadataBlocks$citation$fields$value) {
      if (is.data.frame(metadata) &&
        "keywordValue" %in% names(metadata) &&
        dataset_name %in% metadata$keywordValue$value) {
        existing <- full_dataset
        break
      }
    }
    if (is.list(existing)) {
      break
    }
  }
  return(existing)
}
# top level function for producing metadata
generate_dataset_metadata <- function(dataset, production_date = NA) {

  desc_file <- desc::description$new()
  dataset_meta <- list(
    datasetVersion = list(
      license = "CC0",
      termsOfUse = "CC0 Waiver",
      metadataBlocks = list(
        citation = list(
          displayName = "Citation Metadata",
          fields = get_fields_list(dataset, desc_file, production_date)
        ),
        geospatial = list(
          displayName = "Geospatial Metadata",
          fields = get_geographic_metadata_list(dataset)
        )
      )
    )
  )

  return(dataset_meta)
}
#===== Here begins all the helper functions to produce sub-parts of the metadata =====#
get_fields_list <- function(dataset, desc_file, production_date = NA) {
  if (is.na(production_date)) {
    production_date <- Sys.Date()
  }
  fields_list <- list(
    list(
      typeName = "title",
      multiple = FALSE,
      typeClass = "primitive",
      value = dataset$publication_metadata$title
    ),
    list(
      typeName = "alternativeURL",
      multiple = FALSE,
      typeClass = "primitive",
      value = "http://epiforecasts.io"
    ),
    list(
      typeName = "subject",
      multiple = TRUE,
      typeClass = "controlledVocabulary",
      value = list(
        "Medicine, Health and Life Sciences"
      )
    ),
    list(
      typeName = "productionDate",
      multiple = FALSE,
      typeClass = "primitive",
      value = production_date
    ),
    get_keyword_list(dataset),
    get_author_list(desc_file),
    get_dataset_contact_list(),
    get_dataset_description_list(dataset$publication_metadata),
    get_software_list(desc_file)
  )
  return(fields_list)
}

get_geographic_metadata_list <- function(dataset) {
  meta <- list()
  locations <- list()
  if ("Region" %in% class(dataset)) {
    locations <- append(locations,
                        list(
                          list(
                            country = get_country_list(dataset$publication_metadata$country)
                          )
                        )
    )
  }
  summary_table <- tryCatch(
    read.csv(paste(dataset$summary_dir, "summary_table.csv", sep = "/")),
    warning = function(w) { NA },
    error = function(e) { NA }
  )
  if (!is.na(summary_table)) {
    if (dataset$publication_metadata$breakdown_unit %in% c("state", "region")) {
      for (region in unique(summary_table[[dataset$region_scale]])) {
        location_list <-
          list(
            country = get_country_list(dataset$publication_metadata$country)
          )
        type <- ifelse(dataset$publication_metadata$breakdown_unit == "state", "state", "otherGeographicCoverage")
        location_list[[type]] <-
          list(
            typeName = type,
            multiple = FALSE,
            typeClass = "primitive",
            value = region
          )
        locations <- append(locations,
                            list(location_list)
        )
      }
    }else if (dataset$publication_metadata$breakdown_unit == "continent") {
      for (region in unique(summary_table[[dataset$region_scale]])) {
        locations <- append(locations,
                            list(
                              list(
                                otherGeographicCoverage = list(
                                  typeName = "otherGeographicCoverage",
                                  multiple = FALSE,
                                  typeClass = "primitive",
                                  value = region
                                )
                              )
                            )
        )
      }
    }else if (dataset$publication_metadata$breakdown_unit == "country") {
      for (country in unique(summary_table$Country)) {
        if (country %in% DATAVERSE_COUNTRIES) {
          locations <- append(locations,
                              list(
                                list(
                                  country = get_country_list(country)
                                )
                              )
          )
        }
      }
    }
  }
  if (length(locations) > 0) {
    meta <- append(meta,
                   list(
                     list(
                       typeName = "geographicCoverage",
                       multiple = TRUE,
                       typeClass = "compound",
                       value = locations
                     )
                   )
    )
  }
  meta <- append(meta,
                 list(
                   list(
                     typeName = "geographicUnit",
                     multiple = TRUE,
                     typeClass = "primitive",
                     value = list(
                       dataset$publication_metadata$breakdown_unit
                     )
                   )
                 )
  )
  return(meta)
}
get_author_list <- function(desc_file) {
  # load affiliations
  source(here::here("data/runtime", "known-author-affiliations.R"))
  authors <- list()
  for (desc_author in desc_file$get_authors()) {
    author <- list(
      authorName = list(
        typeName = "authorName",
        multiple = FALSE,
        typeClass = "primitive",
        value = paste0(desc_author$family, ", ", desc_author$given)
      )
    )
    if (!is.null(desc_author$email) && strsplit(desc_author$email, "@", perl = TRUE)[[1]][[2]] %in% names(affiliations)) {
      author$authorAffiliation = list(
        typeName = "authorAffiliation",
        multiple = FALSE,
        typeClass = "primitive",
        value = affiliations[[strsplit(desc_author$email, "@", perl = TRUE)[[1]][[2]]]]
      )
    }
    if ("ORCID" %in% names(desc_author$comment)) {
      author$authorIdentifierScheme = list(
        typeName = "authorIdentifierScheme",
        multiple = FALSE,
        typeClass = "controlledVocabulary",
        value = "ORCID"
      )
      author$authorIdentifier = list(
        typeName = "authorIdentifier",
        multiple = FALSE,
        typeClass = "primitive",
        value = desc_author$comment[["ORCID"]]
      )
    }

    authors <- c(authors, list(author))
  }
  return(list(
    typeName = "author",
    multiple = TRUE,
    typeClass = "compound",
    value = authors
  ))
}
get_keyword_list <- function(dataset) {
  keywords_list <- list()
  keywords <- DATAVERSE_KEYWORDS
  # add in dataset specific ones
  keywords <- c(keywords, dataset$name)

  # build up list
  for (keyword in keywords) {
    keyword_list <- list(
      keywordValue = list(
        typeName = "keywordValue",
        multiple = FALSE,
        typeClass = "primitive",
        value = keyword
      )
    )
    keywords_list <- c(keywords_list, list(keyword_list))
  }

  return(
    list(
      typeName = "keyword",
      multiple = TRUE,
      typeClass = "compound",
      value = keywords_list
    )
  )
}

get_dataset_contact_list <- function() {
  return(
    list(
      typeName = "datasetContact",
      multiple = TRUE,
      typeClass = "compound",
      value = list(
        list(
          datasetContactName = list(
            typeName = "datasetContactName",
            multiple = FALSE,
            typeClass = "primitive",
            value = DATAVERSE_DATA_CONTACT_NAME
          ),
          datasetContactEmail = list(
            typeName = "datasetContactEmail",
            multiple = FALSE,
            typeClass = "primitive",
            value = DATAVERSE_DATA_CONTACT_EMAIL
          )
        )
      )
    )
  )
}

get_dataset_description_list <- function(publication_meta) {
  return(
    list(
      typeName = "dsDescription",
      multiple = TRUE,
      typeClass = "compound",
      value = list(
        list(
          dsDescriptionValue = list(
            typeName = "dsDescriptionValue",
            multiple = FALSE,
            typeClass = "primitive",
            value = publication_meta$description
          )
        )
      )
    )
  )
}

get_software_list <- function(desc_file) {
  epinow2_version <- tryCatch(toString(packageVersion("EpiNow2")), error = function(c) { NA })
  return(
    list(
      typeName = "software",
      multiple = TRUE,
      typeClass = "compound",
      value = list(
        list(
          softwareName = list(
            typeName = "softwareName",
            multiple = FALSE,
            typeClass = "primitive",
            value = "covidrtestimates"
          ),
          softwareVersion = list(
            typeName = "softwareVersion",
            multiple = FALSE,
            typeClass = "primitive",
            value = paste0(desc_file$get_version(), ":", system("git rev-parse HEAD", intern = TRUE))
          )
        ),
        list(
          softwareName = list(
            typeName = "softwareName",
            multiple = FALSE,
            typeClass = "primitive",
            value = "EpiNow2"
          ),
          softwareVersion = list(
            typeName = "softwareVersion",
            multiple = FALSE,
            typeClass = "primitive",
            value = ifelse(is.na(epinow2_version), "unknown", epinow2_version)
          )
        )
      )
    )
  )
}

get_country_list <- function(country) {
  return(list(
    typeName = "country",
    multiple = FALSE,
    typeClass = "controlledVocabulary",
    value = country
  ))
}
