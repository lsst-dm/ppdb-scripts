#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <directory>"
  echo "Please provide the output directory."
  exit 1
fi

output_dir="$1"

if [ ! -d "$output_dir" ]; then
  echo "Directory $output_dir does not exist. Creating it."
  mkdir -p "$output_dir"
fi

echo "Generating DDL for dataset: ${GCP_PROJECT}.${DATASET_ID}"

bq_generate_ddl.py \
  --output-directory $output_dir \
  --project-id $GCP_PROJECT \
  --dataset-name $DATASET_ID
