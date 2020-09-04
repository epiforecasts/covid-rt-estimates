#!/bin/bash

ssh -i $1 $2  'export GITHUB_USERNAME='"'$3'"' && \ 
  export GITHUB_PASSWORD='"'$4'"' && \
  sudo apt-get update -y && \
  sudo apt-get install -y docker.io && \
  echo "$GITHUB_PASSWORD" | sudo docker login --username $GITHUB_USERNAME --password-stdin docker.pkg.github.com  && \
  if cd covid-rt-estimates; then git pull; else git clone https://github.com/epiforecasts/covid-rt-estimates.git; cd covid-rt-estimates; fi && \
  sudo bash bin/update-docker.sh "build" && \
  sudo bash bin/update-via-docker.sh'
  
