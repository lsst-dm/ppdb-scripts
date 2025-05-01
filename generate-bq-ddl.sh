#!/usr/bin/env bash

set -euxo pipefail

DATASET_NAME=${1:-ppdb_dev}
GCP_PROJECT=$(gcloud config get-value project)

echo "Creating BigQuery dataset: ${GCP_PROJECT}.${DATASET_NAME}"

generate_bq_ddl.py \
  --output-directory sql/${DATASET_NAME} \
  --project-id $GCP_PROJECT \
  --dataset-name $DATASET_NAME \
  --include-table DiaObject \
  --include-table DiaSource \
  --include-table DiaForcedSource
