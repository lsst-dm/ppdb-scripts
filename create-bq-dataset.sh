#!/usr/bin/env bash

if [ -z "$1" ]; then
  echo "Usage: $0 <dataset_name>"
  exit 1
fi

_dataset_name=$(gcloud config get-value project):${1}
bq mk --dataset "${_dataset_name}"
echo "Created dataset: ${_dataset_name}"
