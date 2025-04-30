#!/usr/bin/env bash

# This provides the complete environment for running the Dataflow pipeline,
# including execution of local test scripts.

set -euxo pipefail

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

echo "Environment variables set:"
echo "GOOGLE_APPLICATION_CREDENTIALS: $GOOGLE_APPLICATION_CREDENTIALS"
echo "GCP_PROJECT: $GCP_PROJECT"
echo "GCS_BUCKET: $GCS_BUCKET"
echo "DATASET_ID: $DATASET_ID"
echo "DATAFLOW_TEMPLATE_PATH: $DATAFLOW_TEMPLATE_PATH"
echo "IMAGE_URI: $IMAGE_URI"
echo "REGION: $REGION"
echo "SERVICE_ACCOUNT_EMAIL: $SERVICE_ACCOUNT_EMAIL"
echo "STAGING_LOCATION: $STAGING_LOCATION"
echo "TEMP_LOCATION: $TEMP_LOCATION"
echo "TEMPLATE_GCS_PATH: $TEMPLATE_GCS_PATH"
