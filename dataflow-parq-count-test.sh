#!/usr/bin/env bash

# Execute from dax_ppdb/cloud_functions/ingest directory

export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.gcp/keys/ppdb-storage-manager-key.json"
export SERVICE_ACCOUNT=ppdb-storage-manager
export PROJECT_ID=ppdb-dev-438721
export REGION=us-central1
export BUCKET=rubin-ppdb-test-bucket-1

python parq_count_beam_job.py \
  --runner=DataflowRunner \
  --project="${PROJECT_ID}" \
  --region="${REGION}" \
  --temp_location="gs://${BUCKET}/dataflow/temp" \
  --staging_location="gs://${BUCKET}/dataflow/staging" \
  --service_account_email="${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --network=default \
  --input_path="gs://rubin-ppdb-test-bucket-1/data/tmp/2025/04/23/1737056400/DiaSource.parquet"
