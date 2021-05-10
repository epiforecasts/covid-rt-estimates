# System Maintenance Guide

## Quickstart 
### Adding a new location
1. The data for the location needs to be available via epiforecasts/covidregionaldata - check the [system maintenance guide](https://github.com/epiforecasts/covidregionaldata/blob/master/inst/smg/SMG.md) for more information
2. Add your location to the list in R/lists/dataset-list.R (in alphabetical order), setting `stable=FALSE` until testing is complete. Ensure the key is the name. Ensure the name is unique and isn't repeated in the collated-derivative-list (this breaks publishing).
   ```
   Region$new(name = "middle-earth", stable=FALSE),
   ```
3. Run it! `Rscript R/run-region-updates.R -w -u -i middle-earth/*` (executing in very verbose mode, including unstable locations, only include the new location and all sub-locations)
   
   This should take in the order of `(n*80)/cores` minutes where `n` is the number of sub-locations to process

### Adding a new collated derivative
1. Add the collation to R/lists/collated-derivative-list.R  - this should be in a similar style to Regions and an existing one should be fairly self explanatory. Ensure the name is unique and isn't repeated in the dataset-list (this breaks publishing).

## Region - additional control

The region object allows for a range of values to be specified. There are slight differences between superregion and region - the "Object" column below highlights any differences

It is possible to nest multiple different datasets for the same location - check the folder_name and dataset_folder_name options below for examples.

| Property | Object | Mandatory | Default | Purpose | Example |
| -------- |:------:|:---------:|:-------:| ------- | ------- |
| name |  All | Yes | - | this will be treated as the name used in any file path and is the default for covid_regional_data_identifier |  ` name = "germany"` |
| covid_regional_data_identifier <br/><br/> covid_national_data_identifier |  Region <br/><br/> SuperRegion | No | name <br/><br/> "ecdc"| Used for the call to covidregionaldata::get_regional_data / covidregionaldata::get_national_data to specify the country / source parameter. Used to shim inconsistencies between the two libraries (e.g. united-kingdom / UK ). Name differs between region / superregion. | ` covid_regional_data_identifier = "UK"` |
|case_modifier |  All | No | NA | A lambda that modifies the `cases` object. This is expected to return the cases object. It allows for additional filtering or modifying of the source data if needed. This should be used with caution as it provides a method of "tinkering" with the source data with potential loss of data integrity. | `case_modifier = function(cases) { ... return(cases)}` |
|generation_time |  All | No | loads "data/generation_time.rds" | Optionally provide alternative data object to replace that loaded from the generic generation_time.rds file | `generation_time = readRDS(here::here("data", "alternative_generation_time.rds"))` |
|incubation_period |  All | No | loads "data/incubation_period.rds" | Optionally provide alternative data object to replace that loaded from the generic incubation_period.rds file | `incubation_period = readRDS(here::here("data", "alternative_incubation.rds"))` |
|reporting_delay |  All | No | loads "data/onset_to_admission_delay.rds" | Optionally provide alternative data object to replace that loaded from the generic onset_to_admission_delay.rds file | `reporting_delay = readRDS(here::here("data", "alternative_delay.rds"))` |
|cases_subregion_source |  Region | No | "level_1_region" | If the columns returned by covidregionaldata are not using the standard naming this can be reused to map the correct column for region | `cases_subregion_source = ...` |
|data_args |  Region | No | NULL | Optional extra arguments to hand to the get_regional_data method | `data_args = list(nhsregions = TRUE)` |
|region_scale |  Region <br/><br/> SuperRegion | No | "Region" <br/><br/> "Country" | Used to refer to the region in report. E.g. "State" for USA | `region_scale = "State"` |
|stable |  All | No | TRUE | Controls if it is eligible for inclusion in a full run. Regions under development (or suffering from data issues) can be flagged as `stable=FALSE` and excluded by default| `stable = FALSE` |
|folder_name |  All | No | NA | if specified it replaces the dataset name in the folder structure | `folder_name="USA"` |
|dataset_folder_name|  Region | No | "cases" | allows for specifying the dataset is something other than cases. Typically used as a pair with the folder_name flag to co-locate to datasets sensible | `name="uk-hospital-admissions", folder_name="united-kingdom", dataset_folder_name="hospital-admissions"` with another dataset of `name="united-kingdom"` - this will produce data in `subnational/united-kingdom/<cases or hospital-admissions>/...`|