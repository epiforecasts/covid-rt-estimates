#!/bin/bash


# Remove last update flag
rm last-update/update-complete

# Run all stable countries and global datasets
printf "Run for all regional locations"
Rscript R/run-region-updates.R

# Add update complete flag
touch last-update/update-complete