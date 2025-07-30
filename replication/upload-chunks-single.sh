#!/usr/bin/env bash

set -euo pipefail

# Prevent sourcing — this script must be executed, not sourced
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  echo "Error: this script must be executed, not sourced." >&2
  return 1
fi

# Make sure the check_var function is available
if ! declare -F check_var >/dev/null; then
  echo "check_var is not defined." >&2
  exit 1
fi

check_var "LOG_LEVEL" "INFO"
check_var "GCP_PROJECT"
check_var "GCS_BUCKET"
check_var "DATASET_ID"
check_var "PPDB_STAGING_DIR"

ppdb-replication \
    --log-level ${LOG_LEVEL} \
    upload-chunks \
    --bucket ${GCS_BUCKET} \
    --dataset ${GCP_PROJECT}:${DATASET_ID} \
    --wait-interval 0 \
    --upload-interval 0 \
    --prefix data/tmp \
    --exit-on-empty \
    --exit-on-error \
    ${PPDB_CONFIG_FILE}
