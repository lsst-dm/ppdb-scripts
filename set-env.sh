#!/usr/bin/env bash

# This provides the complete environment for running the Dataflow pipeline,
# including execution of local test scripts.

export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.gcp/keys/ppdb-storage-manager-key.json"

export GCP_PROJECT="ppdb-dev-438721"
export GCS_BUCKET="rubin-ppdb-test-bucket-1"
export DATASET_ID="ppdb_dev"
export DATAFLOW_TEMPLATE_PATH="gs://${GCS_BUCKET}/templates/stage_chunk_flex_template.json"
export IMAGE_URI="gcr.io/${GCP_PROJECT}/stage-chunk-image"
export REGION="us-central1"
export SERVICE_ACCOUNT_EMAIL="ppdb-storage-manager@${GCP_PROJECT}.iam.gserviceaccount.com"
export STAGING_LOCATION="gs://${GCS_BUCKET}/dataflow/staging"
export TEMP_LOCATION="gs://${GCS_BUCKET}/dataflow/temp"
export TEMPLATE_GCS_PATH="gs://${GCS_BUCKET}/templates/stage_chunk_flex_template.json"
