
# National and subnational estimates of the time-varying reproduction number for Covid-19

[![MIT license](https://img.shields.io/badge/License-MIT-blue.svg)](https://lbesson.mit-license.org/) [![Status](https://img.shields.io/badge/Status-csv-yellow.svg)](https://github.com/epiforecasts/covid-rt-estimates/blob/master/status.csv) [![Website epiforecasts.io/covid](https://img.shields.io/website-up-down-green-red/https/epiforecasts.io/covid/)](https://epiforecasts.io/covid/) [![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://GitHub.com/epiforecasts/covid-rt-estimates/graphs/commit-activity) [![Average time to resolve an issue](http://isitmaintained.com/badge/resolution/epiforecasts/covid-rt-estimates.svg)](http://isitmaintained.com/project/epiforecasts/covid-rt-estimates "Average time to resolve an issue") [![Percentage of issues still open](http://isitmaintained.com/badge/open/epiforecasts/covid-rt-estimates.svg)](http://isitmaintained.com/project/epiforecasts/covid-rt-estimates "Percentage of issues still open")

This repository contains estimates of the time-varying reproduction number for every country in the world listed in the ECDC Covid-19 data source and subnational estimates for 9 countries. 

Summarised estimates as csv's can be found in the `**/summary` folders. National estimates can be found in the `national` folder and subnational estimates in the `subnational/country` subfolder depending on the country of interest. 

All regions have Rt estimates based on case counts. In some regions, we also separately estimate Rt using counts of hospital admissions or deaths. The differences between each of these estimates might suggest uneven or changing transmission by age and/or severity in the general population. For more on the influence and different uses of data source on Rt, see [here](https://github.com/epiforecasts/rt-comparison-uk-public).

## Latest results
Estimates are generated using [`{EpiNow2}`](https://epiforecasts.io/EpiNow2/) and presented on [epiforecasts.io/covid](https://epiforecasts.io/covid) (which also outlines the method used). If using these estimates please consider citing our associated [paper](https://wellcomeopenresearch.org/articles/5-112). All the datasets are published on [Harvard Dataverse](https://dataverse.harvard.edu/dataverse/covid-rt) providing a citable source for a particular version of a data set. For the technically inclined this provides a [full API](https://guides.dataverse.org/en/latest/api/dataaccess.html) to allow interacting with datasets or pulling the latest version of a particular file.


To confirm the latest version check the production date in the metadata tab on the relevant harvard dataverse link. Alternatively check the Version tab to see how recently it was produced (Note EST timezone).

| Dataset | Produced? | Dataverse Location |  rt / summary files |
|---------|-----------|--------------------|---------------------|
| regional-cases | :heavy_check_mark: | [doi:10.7910/DVN/K2PXLV](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/K2PXLV ) | [summary_table](https://dataverse.harvard.edu/api/access/datafile/4159967?format=original&gbrecs=true) |
| regional-deaths | :heavy_check_mark: | [doi:10.7910/DVN/A12ADQ](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/A12ADQ ) | [rt](https://dataverse.harvard.edu/api/access/datafile/4159096?format=original&gbrecs=true) / [summary_table](https://dataverse.harvard.edu/api/access/datafile/4158354?format=original&gbrecs=true) |
| cases | :heavy_check_mark: | [doi:10.7910/DVN/TTLQRN](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/TTLQRN ) | [summary_table](https://dataverse.harvard.edu/api/access/datafile/4158624?format=original&gbrecs=true) |
| deaths | :heavy_check_mark: | [doi:10.7910/DVN/RBZVJE](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/RBZVJE ) | [summary_table](https://dataverse.harvard.edu/api/access/datafile/4159803?format=original&gbrecs=true) |
| afghanistan | :x: |  | |
| belgium | :heavy_check_mark: | [doi:10.7910/DVN/B4UO2L](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/B4UO2L ) | [rt](https://dataverse.harvard.edu/api/access/datafile/4158650?format=original&gbrecs=true) / [summary_table](https://dataverse.harvard.edu/api/access/datafile/4158652?format=original&gbrecs=true) |
| brazil | :heavy_check_mark: | [doi:10.7910/DVN/METDW2](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/METDW2 ) | [rt](https://dataverse.harvard.edu/api/access/datafile/4159119?format=original&gbrecs=true) / [summary_table](https://dataverse.harvard.edu/api/access/datafile/4159121?format=original&gbrecs=true) |
| canada | :heavy_check_mark: | [doi:10.7910/DVN/2CNKZJ](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/2CNKZJ ) | [rt](https://dataverse.harvard.edu/api/access/datafile/4159130?format=original&gbrecs=true) / [summary_table](https://dataverse.harvard.edu/api/access/datafile/4159132?format=original&gbrecs=true) |
| colombia | :heavy_check_mark: | [doi:10.7910/DVN/GI8EVP](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/GI8EVP ) | [rt](https://dataverse.harvard.edu/api/access/datafile/4159143?format=original&gbrecs=true) / [summary_table](https://dataverse.harvard.edu/api/access/datafile/4159145?format=original&gbrecs=true) |
| germany | :heavy_check_mark: | [doi:10.7910/DVN/LNMJYJ](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/LNMJYJ ) | [rt](https://dataverse.harvard.edu/api/access/datafile/4159156?format=original&gbrecs=true) / [summary_table](https://dataverse.harvard.edu/api/access/datafile/4159158?format=original&gbrecs=true) |
| india | :heavy_check_mark: | [doi:10.7910/DVN/PRP6CY](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/PRP6CY ) | [rt](https://dataverse.harvard.edu/api/access/datafile/4152410?format=original&gbrecs=true) / [summary_table](https://dataverse.harvard.edu/api/access/datafile/4152412?format=original&gbrecs=true) |
| italy | :heavy_check_mark: | [doi:10.7910/DVN/8DUSHZ](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/8DUSHZ ) | [rt](https://dataverse.harvard.edu/api/access/datafile/4159167?format=original&gbrecs=true) / [summary_table](https://dataverse.harvard.edu/api/access/datafile/4159169?format=original&gbrecs=true) |
| russia | :heavy_check_mark: | [doi:10.7910/DVN/XPULZP](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/XPULZP ) | [rt](https://dataverse.harvard.edu/api/access/datafile/4157566?format=original&gbrecs=true) / [summary_table](https://dataverse.harvard.edu/api/access/datafile/4157567?format=original&gbrecs=true) |
| united-kingdom | :heavy_check_mark: | [doi:10.7910/DVN/S07EZB](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/S07EZB ) | [rt](https://dataverse.harvard.edu/api/access/datafile/4159749?format=original&gbrecs=true) / [summary_table](https://dataverse.harvard.edu/api/access/datafile/4159752?format=original&gbrecs=true) |
| united-kingdom-deaths | :heavy_check_mark: | [doi:10.7910/DVN/QVWUJ5](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/QVWUJ5 ) | [rt](https://dataverse.harvard.edu/api/access/datafile/4150553?format=original&gbrecs=true) / [summary_table](https://dataverse.harvard.edu/api/access/datafile/4150555?format=original&gbrecs=true) |
| united-kingdom-admissions | :heavy_check_mark: | [doi:10.7910/DVN/CCE4XT](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/CCE4XT ) | [rt](https://dataverse.harvard.edu/api/access/datafile/4159813?format=original&gbrecs=true) / [summary_table](https://dataverse.harvard.edu/api/access/datafile/4159815?format=original&gbrecs=true) |
| united-states | :heavy_check_mark: | [doi:10.7910/DVN/K2PXLV](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/BZ7FPH ) | [rt](https://dataverse.harvard.edu/api/access/datafile/4159832?format=original&gbrecs=true) / [summary_table](https://dataverse.harvard.edu/api/access/datafile/4159834?format=original&gbrecs=true) |

## Updating the estimates

1. Clone the repository.

```bash
git clone https://github.com/epiforecasts/covid-rt-estimates.git
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
