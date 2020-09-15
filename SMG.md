# System Maintenance Guide

## Quickstart - adding a new location
1. The data for the location needs to be available via epiforecasts/covidregionaldata - check the [system maintenance guide](https://github.com/epiforecasts/covidregionaldata/blob/master/inst/smg/SMG.md) for more information
2. Add your location to the list in R/dataset-list.R (in alphabetical order), setting `stable=FALSE` until testing is complete
   ```
   Region$new(name = "middle-earth", stable=FALSE),
   ```
3. Run it! `Rscript R/run-region-updates.R -w -u -i middle-earth/*` (executing in very verbose mode, including unstable locations, only include the new location and all sub-locations)
   
   This should take in the order of `(n*80)/cores` minutes where `n` is the number of sub-locations to process

## Region - additional control

The region object allows for a range of values to be specified.

| Property | Mandatory | Default | Purpose | Example |
| -------- |:---------:|:-------:| ------- | ------- |
| name | Yes | - | this will be treated as the name used in any file path and is the default for covid_regional_data_identifier |  ` name = "germany"` |
| covid_regional_data_identifier | No | name | Used for the call to covidregionaldata::get_regional_data to specify the country parameter. Used to shim inconsistencies between the two libraries (e.g. united-kingdom / UK ) | ` covid_regional_data_identifier = "UK"` |
|case_modifier | No | NA | A lambda that modifies the `cases` object. This is expected to return the cases object. It allows for additional filtering or modifying of the source data if needed. This should be used with caution as it provides a method of "tinkering" with the source data with potential loss of data integrity. | `case_modifier = function(cases) { ... return(cases)}` |
|generation_time | No | loads "data/generation_time.rds" | Optionally provide alternative data object to replace that loaded from the generic generation_time.rds file | `generation_time = readRDS(here::here("data", "alternative_generation_time.rds"))` |
|incubation_period | No | loads "data/incubation_period.rds" | Optionally provide alternative data object to replace that loaded from the generic incubation_period.rds file | `incubation_period = readRDS(here::here("data", "alternative_incubation.rds"))` |
|reporting_delay | No | loads "data/onset_to_admission_delay.rds" | Optionally provide alternative data object to replace that loaded from the generic onset_to_admission_delay.rds file | `reporting_delay = readRDS(here::here("data", "alternative_delay.rds"))` |
|cases_subregion_source | No | "Region" | If the columns returned by covidregionaldata are not using the standard naming this can be reused to map the correct column for region | `cases_subregion_source = ...` |
|region_scale | No | "Region" | Used to refer to the region in report. E.g. "State" for USA | `region_scale = "State"` |
|stable | No | TRUE | Controls if it is eligible for inclusion in a full run. Regions under development (or suffering from data issues) can be flagged as `stable=FALSE` and excluded by default| `stable = FALSE` |