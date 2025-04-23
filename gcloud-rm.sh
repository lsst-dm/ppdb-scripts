#!/usr/bin/env bash

# read -p "Are you sure you want to delete all contents under data/tmp/? [Y/N] " confirm
# if [[ "$confirm" == [yY] ]]; then
gcloud storage rm --recursive gs://rubin-ppdb-test-bucket-1/data/tmp/
# else
#    echo "Aborted."
#fi
