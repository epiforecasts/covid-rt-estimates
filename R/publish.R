publish_data <- function(dataset) {
  if (exists("DATAVERSE_SERVER") && exists("DATAVERSE_KEY")) {
    Sys.setenv("DATAVERSE_SERVER" = DATAVERSE_SERVER)
    Sys.setenv("DATAVERSE_KEY" = DATAVERSE_KEY)
    if (require(dataverse)) {
      library(rjson) # this is needed to handle the templating of json
      library(desc) # this is used to get the author data from the DESCRIPTION file
      existing_id <- check_for_existing_id(dataset$name)
      if (is.na(existing_id)) {
        existing_id <- create_new_dataset(dataset)
      }
      # loop  through the summary dir adding all the files
      for (file in dir(dataset$summary_dir)) {
        add_dataset_file(file, existing_id)
      }
      publish_dataset(existing_id)
    }else {
      futile.logger::flog.debug("Dataverse not enabled, no attempt to publish")
    }
  }else {
    futile.logger::flog.debug("No dataverse credentials loaded, no attempt to publish")
  }
}

check_for_existing_id <- function(dataset_name) {
  # load existing
  datasets <-
    dataverse_contents(DATAVERSE_VERSEID, key = DATAVERSE_KEY, server = DATAVERSE_SERVER)
  existing_id <- NA
  for (dataset in datasets) {
    full_dataset <- get_dataset(dataset$id)
    # for some reason the metadata keywords are inside the citation block... go figure
    # loop over them looking for the keyword value and then check if it's the name of the dataset.
    for (metadata in full_dataset$metadataBlocks$citation$fields$value) {
      if (is.data.frame(metadata) &&
        "keywordValue" %in% names(metadata) &&
        metadata$keywordValue$value == dataset$name) {
        existing_id <- dataset$id
        break
      }
    }
    if (!is.na(existing_id)) {
      break
    }
  }
  return(existing_id)
}

create_new_dataset <- function(dataset) {

  desc_file <- description$new()
  dataset_meta <- list(
    datasetVersion = list(
      license = "CC0",
      termsOfUse = "CC0 Waiver",
      metadataBlocks = list(
        citation = list(
          displayName = "Citation Metadata",
          fields = list(
            list(
              typeName = "title",
              multiple = FALSE,
              typeClass = "primitive",
              value = dataset$publication_meta$title
            ),
            list(
              typeName = "alternativeURL",
              multiple = FALSE,
              typeClass = "primitive",
              value = "http://epiforecasts.io"
            ),
            list(
              typeName = "author",
              multiple = TRUE,
              typeClass = "compound",
              value = get_author_list(desc_file)
            ),
            get_dataset_contact(),
            get_dataset_description(dataset),
            list(
              typeName = "subject",
              multiple = TRUE,
              typeClass = "controlledVocabulary",
              value = list(
                "Medicine, Health and Life Sciences"
              )
            ),
            list(
              typeName = "keyword",
              multiple = TRUE,
              typeClass = "compound",
              value = list(
                list(
                  keywordValue = list(
                    typeName = "keywordValue",
                    multiple = FALSE,
                    typeClass = "primitive",
                    value = dataset$name
                  )
                )
              )
            )
          )
        )
      )
    )
  )

  ds <- create_dataset(DATAVERSE_VERSEID, toJSON(dataset_meta))
  return(ds)
}

get_author_list <- function(desc_file) {
  # load affiliations
  source(here::here("data/runtime", "known-author-affiliations.R"))
  authors <- list()
  for (desc_author in desc_file$get_authors()) {
    author = list(
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
    if (!is.null(desc_author$comment)) {
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
        value = strsplit(desc_author$comment, '"', perl = TRUE)[[1]]
      )
    }

    authors <- c(authors, list(author))
  }
  return(authors)
}

get_dataset_contact <- function() {
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

get_dataset_description <- function(publication_meta) {
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
            value = publication_meta$
),
)
)
)
)
}