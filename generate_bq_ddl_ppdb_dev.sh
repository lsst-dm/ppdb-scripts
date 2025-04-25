#!/usr/bin/env bash

set -e
set -x

DATASET_NAME=${1:-ppdb_dev}
PROJECT_ID=$(gcloud config get-value project)

echo "Creating BigQuery dataset: ${PROJECT_ID}.${DATASET_NAME}"

generate_bq_ddl.py \
  --output-directory sql/${DATASET_NAME} \
  --project-id $PROJECT_ID \
  --dataset-name $DATASET_NAME \
  --include-table DiaObject \
  --include-table DiaSource \
  --include-table DiaForcedSource
