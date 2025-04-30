#!/usr/bin/env bash

set -euxo pipefail

# Ensure the required environment variable is set
if [ -z "${GCP_PROJECT+x}" ]; then
  echo "PROJECT_ID is not set. Please set it to your Google Cloud project ID."
  exit 1
fi

# Truncate tables in BigQuery
echo "Truncating tables in project ${GCP_PROJECT}..."

bq query --use_legacy_sql=false "TRUNCATE TABLE \`${GCP_PROJECT}.ppdb_dev.DiaObject\`"
bq query --use_legacy_sql=false "TRUNCATE TABLE \`${GCP_PROJECT}.ppdb_dev.DiaSource\`"
bq query --use_legacy_sql=false "TRUNCATE TABLE \`${GCP_PROJECT}.ppdb_dev.DiaForcedSource\`"

echo "Tables truncated successfully."