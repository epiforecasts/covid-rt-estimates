
# National and subnational estimates of the time-varying reproduction number for Covid-19

[![MIT license](https://img.shields.io/badge/License-MIT-blue.svg)](https://lbesson.mit-license.org/) [![Status](https://img.shields.io/badge/Status-csv-yellow.svg)](https://github.com/epiforecasts/covid-rt-estimates/blob/master/status.csv) [![Website epiforecasts.io/covid](https://img.shields.io/website-up-down-green-red/https/epiforecasts.io/covid/)](https://epiforecasts.io/covid/) 

This repository contains estimates of the time-varying reproduction number for every country in the world listed in the ECDC Covid-19 data source and subnational estimates for 9 countries. 

Summarised estimates as csv's can be found in the `**/summary` folders. National estimates can be found in the `national` folder and subnational estimates in the `subnational/country` subfolder depending on the country of interest. 

All regions have Rt estimates based on case counts. In some regions, we also separately estimate Rt using counts of hospital admissions or deaths. The differences between each of these estimates might suggest uneven or changing transmission by age and/or severity in the general population. For more on the influence and different uses of data source on Rt, see [here](https://github.com/epiforecasts/rt-comparison-uk-public).

## Reconstructing historical estimates and forecasts

This repository only stored the most recent forecasts (a rolling 14-day window).
To reconstruct a complete historical time series of all forecasts (e.g., for retrospective forecast evaluation), you can use the R function in [this gist](https://gist.github.com/sbfnk/d2900c745312219e3e48e08adde47cde) which:

1. Queries the git history for all commits that modified a given forecast CSV file
2. Downloads the data from each historical commit
3. Combines overlapping estimates by taking medians

Example usage:

```r
# Install required packages
# install.packages(c("gh", "readr", "dplyr", "tidyr"))

source("https://gist.githubusercontent.com/sbfnk/d2900c745312219e3e48e08adde47cde/raw/get_covid19_nowcasts.R")

# Get historical Rt estimates for a country
estimates <- get_covid19_nowcasts(
  dataset = "national/cases",
  variable = "rt",
  earliest_date = "2020-08-30"
)
```

If you have any questions about reconstructing historical data, please [open an issue](https://github.com/epiforecasts/covid-rt-estimates/issues).

## Latest results (as of 31 March 2022)

Estimates are generated using [`{EpiNow2}`](https://epiforecasts.io/EpiNow2/) and presented on [epiforecasts.io/covid](https://epiforecasts.io/covid) (which also outlines the method used). If using these estimates please consider citing our associated [paper](https://wellcomeopenresearch.org/articles/5-112).

To confirm the latest version check the production date in the metadata tab on the relevant github link. Alternatively check the Version tab to see how recently it was produced (Note EST timezone).

| Dataset | Produced? | rt / summary files |
|---------|-----------|---------------------|
regional-cases | :heavy_check_mark: | https://github.com/epiforecasts/covid-rt-estimates/tree/master/region/cases/summary |
regional-deaths | :heavy_check_mark: | https://github.com/epiforecasts/covid-rt-estimates/tree/master/region/deaths/summary |
cases | :heavy_check_mark: | https://github.com/epiforecasts/covid-rt-estimates/tree/master/national/cases/summary |
deaths | :heavy_check_mark: | https://github.com/epiforecasts/covid-rt-estimates/tree/master/national/deaths/summary |
belgium | :heavy_check_mark: | https://github.com/epiforecasts/covid-rt-estimates/tree/master/subnational/belgium/cases/summary |
brazil | :heavy_check_mark: | https://github.com/epiforecasts/covid-rt-estimates/tree/master/subnational/brazil/cases/summary |
canada | :heavy_check_mark: | https://github.com/epiforecasts/covid-rt-estimates/tree/master/subnational/canada/cases/summary |
colombia | :heavy_check_mark: | https://github.com/epiforecasts/covid-rt-estimates/tree/master/subnational/colombia/cases/summary |
germany | :heavy_check_mark: | https://github.com/epiforecasts/covid-rt-estimates/tree/master/subnational/germany/cases/summary |
india | :x: | https://github.com/epiforecasts/covid-rt-estimates/tree/master/subnational/india/cases/summary |
italy | :heavy_check_mark: | https://github.com/epiforecasts/covid-rt-estimates/tree/master/subnational/italy/cases/summary |
russia | :x: | https://github.com/epiforecasts/covid-rt-estimates/tree/master/subnational/russia/cases/summary |
united-kingdom | :heavy_check_mark: | https://github.com/epiforecasts/covid-rt-estimates/tree/master/subnational/united-kingdom/cases/summary |
united-kingdom-deaths | :heavy_check_mark: | https://github.com/epiforecasts/covid-rt-estimates/tree/master/subnational/united-kingdom/deaths/summary |
united-kingdom-admissions | :heavy_check_mark: | https://github.com/epiforecasts/covid-rt-estimates/tree/master/subnational/united-kingdom/admissions/summary |
united-kingdom-local | :heavy_check_mark: | https://github.com/epiforecasts/covid-rt-estimates/tree/master/subnational/united-kingdom-local/cases/summary |
united-kingdom-local-deaths | :heavy_check_mark: | https://github.com/epiforecasts/covid-rt-estimates/tree/master/subnational/united-kingdom-local/deaths/summary |
united-kingdom-local-admissions | :heavy_check_mark: | https://github.com/epiforecasts/covid-rt-estimates/tree/master/subnational/united-kingdom-local/admissions/summary |
united-states | :heavy_check_mark: | https://github.com/epiforecasts/covid-rt-estimates/tree/master/subnational/united-states/cases/summary |

## Updating the estimates

1. Clone the repository (*This results in shallow clone with just the HEAD commit, remove the `--depth` flag for a full clone but note that this will take some time as the full history is large*).

```bash
git clone --depth 1 https://github.com/epiforecasts/covid-rt-estimates.git
```

### Using a remote server

Run the following on the command line replacing `path-to-key`, `username@public-ip-of-server`, `github-username`, and `github-pat` with your information. *Note this is not a secure way of transferring your GitHub PAT.*

```bash
curl --fail https://raw.githubusercontent.com/epiforecasts/covid-rt-estimates/master/bin/update-via-ssh.sh > update-via-ssh.sh
sudo bash update-via-ssh.sh path-to-key username@public-ip-of-server github-username github-pat
```

See `bin/update-via-ssh.sh` for details on what this script is doing and the more detailed step by step instructions below.

### Using Docker

2. Log in to GitHub Docker package repository.

```bash
docker login docker.pkg.github.com
```

#### Script approach


3. (Optional - must be done at least once) Update the docker container (by default this pulls a built image passing `"build"` instead triggers a build based on local files).

```bash
sudo bash bin/update-docker.sh
```

3. Run the following in a bash terminal (see `docker logs covidrtestimates` for runtime information).

```bash
sudo bash bin/update-via-docker.sh
```

#### Step by step


3. (Optional) Build the docker container locally.

```bash
docker build . -t covidrtestimates
```

4. (Optional). Alternatively pull the built docker container.

```bash
docker pull docker.pkg.github.com/epiforecasts/covid-rt-estimates/covidrtestimates:latest
docker tag docker.pkg.github.com/epiforecasts/covid-rt-estimates/covidrtestimates:latest covidrtestimates
```

5. Update the estimates (see `docker logs covidrtestimates` for runtime information).

```bash
# This command uses the code that ships with in the docker image. You can use
# your own version by mounting it in the container
sudo docker run -d --user rstudio --name covidrtestimates covidrtestimates /bin/bash bin/update-estimates.sh
```


### Using R

2. Install dependencies.

```r
devtools::install_dev_deps()
```

3.  Run `Rscript R/run-region-updates.R`. 

   Adding `--help` will show documentation and the command options. This can run all or some regions and subregions, control logging, exclude unstable regions and set the maximum execution time for each set of analysis.
   
   Note: Currently regions are either global or country level but the region/subregion pattern could be reused on any level of parent/child geographic dataset.
   
   A timing log will be output and updated in runtimes.csv. Times of -1 = error and 999999 = killed by timeout

## Development environment

This analysis was developed in a docker container based on the `epinow2` docker image.

To build the docker image run (from the `covid-rt-estimates` directory):

``` bash
docker build . -t covidrtestimates
```

Alternatively to use the prebuilt image first login into the GitHub package repository using your GitHub credentials (if you have not already done so) and then run the following:

```bash
# docker login docker.pkg.github.com
docker pull docker.pkg.github.com/epiforecasts/covid-rt-estimates/covidrtestimates:latest
docker tag docker.pkg.github.com/epiforecasts/covid-rt-estimates/covidrtestimates:latest covidrtestimates
```
To run the docker image run:

``` bash
docker run -d -p 8787:8787 --name covidrtestimates -e USER=covidrtestimates -e PASSWORD=covidrtestimates covidrtestimates
```

The rstudio client can be found on port :8787 at your local machines ip.
The default username:password is covidrtestimates:covidrtestimates, set the user with -e
USER=username, and the password with - e PASSWORD=newpasswordhere. The
default is to save the analysis files into the user directory.

To mount a folder (from your current working directory - here assumed to
be `tmp`) in the docker container to your local system use the following
in the above docker run command (as given mounts the whole `covidrtestimates`
directory to `tmp`).

``` bash
--mount type=bind,source=$(pwd)/tmp,target=/home/covidrtestimates
```

To access the command line run the following:

``` bash
docker exec -ti covidrtestimates bash
```
To add another country see [SMG.md](./SMG.md)
