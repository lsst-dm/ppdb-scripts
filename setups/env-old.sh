#!/usr/bin/env bash

# FIXME: This has been broken up into multiple scripts. DO NOT USE.

# This provides the complete environment for running the Dataflow pipeline,
# including execution of local test scripts.

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"

check_env_dir() {
    local varname="$1"
    local dir="${!varname}"
    if [[ -z "$dir" ]]; then
        echo "Environment variable $varname is not set."
        return 1
    elif [[ ! -d "$dir" ]]; then
        echo "Environment variable $varname does not point to a valid directory: $dir"
        return 2
    else
        echo "$varname points to valid dir: $dir"
        return 0
    fi
}

check_env_file() {
    local varname="$1"
    local file="${!varname}"
    if [[ -z "$file" ]]; then
        echo "Environment variable $varname is not set."
        return 1
    elif [[ ! -f "$file" ]]; then
        echo "Environment variable $varname does not point to a valid file: $file"
        return 2
    else
        echo "$varname points to valid file: $file"
        return 0
    fi
}

# == GCP ENVIRONMENT ==
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.gcp/keys/ppdb-storage-manager-key.json"
export GCP_PROJECT="ppdb-dev-438721"
export GCS_BUCKET="rubin-ppdb-test-bucket-1"
export SERVICE_ACCOUNT_EMAIL="ppdb-storage-manager@${GCP_PROJECT}.iam.gserviceaccount.com"
export REGION="us-central1"

# == DATAFLOW ENVIRONMENT ==
export DATASET_ID="ppdb_dm50567"
export DATAFLOW_TEMPLATE_PATH="gs://${GCS_BUCKET}/templates/stage_chunk_flex_template.json"
export IMAGE_URI="gcr.io/${GCP_PROJECT}/stage-chunk-image"
export STAGING_LOCATION="gs://${GCS_BUCKET}/dataflow/staging"
export TEMP_LOCATION="gs://${GCS_BUCKET}/dataflow/temp"
export TEMPLATE_GCS_PATH="gs://${GCS_BUCKET}/templates/stage_chunk_flex_template.json"

# == PPDB & APDB ENVIRONMENT ==
export PPDB_CONFIG_FILE="${SCRIPT_PATH}/../ppdb-config/ppdb_dm50567.yaml"
export APDB_CONFIG_FILE="s3://rubin-pp-dev-users/apdb_config/cassandra/pp_apdb_lsstcomcamsim-dev.py"
export AWS_SHARED_CREDENTIALS_FILE=$HOME/.aws/aws-credentials.ini
export SDM_SCHEMAS_DIR="${SCRIPT_PATH}/../sdm_schemas"
export PPDB_STAGING_DIR="${SCRIPT_PATH}/../ppdb_staging"
export LOG_LEVEL="INFO"

check_env_file "GOOGLE_APPLICATION_CREDENTIALS"
check_env_file "PPDB_CONFIG_FILE"
check_env_file "AWS_SHARED_CREDENTIALS_FILE"

check_env_dir "SDM_SCHEMAS_DIR"
check_env_dir "PPDB_STAGING_DIR"

# == PRINT ENVIRONMENT ==
echo -e "\nEnvironment variables set:"
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
