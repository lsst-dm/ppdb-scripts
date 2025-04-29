#!/usr/bin/env bash

# Execute from directory: dax_ppdb/cloud_functions/stage_chunk

export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.gcp/keys/ppdb-storage-manager-key.json"

PROJECT_ID="ppdb-dev-438721"
REGION="us-central1"
BUCKET="rubin-ppdb-test-bucket-1"
DATASET_ID="ppdb_dev"
TEMP_LOCATION="gs://${BUCKET}/dataflow/temp"
SERVICE_ACCOUNT=ppdb-storage-manager

python stage_chunk_beam_job.py \
  --runner=DataflowRunner \
  --project="${PROJECT_ID}" \
  --region="${REGION}" \
  --temp_location="${TEMP_LOCATION}" \
  --staging_location="gs://${BUCKET}/dataflow/staging" \
  --input_path="gs://${BUCKET}/data/tmp/2025/04/23/1737056400" \
  --dataset_id="${DATASET_ID}" \
  --service_account_email="${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com"
