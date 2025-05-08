#!/usr/bin/env bash

# This provides the complete environment for running the Dataflow pipeline,
# including execution of local test scripts.

set -euo pipefail

# == GCP ENVIRONMENT ==
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.gcp/keys/ppdb-storage-manager-key.json"
export GCP_PROJECT="ppdb-dev-438721"
export GCS_BUCKET="rubin-ppdb-test-bucket-1"
export SERVICE_ACCOUNT_EMAIL="ppdb-storage-manager@${GCP_PROJECT}.iam.gserviceaccount.com"
export REGION="us-central1"

# == DATAFLOW ENVIRONMENT ==
export DATASET_ID="ppdb_dev"
export DATAFLOW_TEMPLATE_PATH="gs://${GCS_BUCKET}/templates/stage_chunk_flex_template.json"
export IMAGE_URI="gcr.io/${GCP_PROJECT}/stage-chunk-image"
export STAGING_LOCATION="gs://${GCS_BUCKET}/dataflow/staging"
export TEMP_LOCATION="gs://${GCS_BUCKET}/dataflow/temp"
export TEMPLATE_GCS_PATH="gs://${GCS_BUCKET}/templates/stage_chunk_flex_template.json"

# == PPDB & APDB ENVIRONMENT ==
export PPDB_CONFIG_FILE="$HOME/.ppdb/ppdb_dm-49202.yaml"
export APDB_CONFIG_FILE="s3://rubin-pp-dev-users/apdb_config/cassandra/pp_apdb_lsstcomcamsim-dev.py"
export AWS_SHARED_CREDENTIALS_FILE=$HOME/.aws/aws-credentials.ini  #
export SDM_SCHEMAS_DIR="$HOME/.ppdb/sdm_schemas"  # TODO: Eventually replace by reading from lsst resource.
export PPDB_STAGING_DIR="$HOME/.ppdb/staging"
export LOG_LEVEL="INFO"

# == PRINT ENVIRONMENT ==
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
echo "APDB_CONFIG_FILE: $APDB_CONFIG_FILE"
echo "PPDB_STAGING_DIR: $PPDB_STAGING_DIR"
echo "PPDB_CONFIG_FILE: $PPDB_CONFIG_FILE"
echo "SDM_SCHEMAS_DIR: $SDM_SCHEMAS_DIR"
echo "LOG_LEVEL: $LOG_LEVEL"
