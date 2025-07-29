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

check_var "GCP_PROJECT"
check_var "PPDB_SCHEMA_NAME"
check_var "DATASET_ID"

# Y/N confirmation
read -p "Are you sure you want to truncate all tables in ${GCP_PROJECT}:${DATASET_ID}? [y/N] " confirm
case "$confirm" in
    [yY]) ;;
    *) echo "Aborted."; exit 1 ;;
esac

# Truncate tables in BigQuery
echo "Truncating tables in \`${GCP_PROJECT}:${DATASET_ID}\`..."

for table_name in DiaObject DiaSource DiaForcedSource; do
  bq query --use_legacy_sql=false "TRUNCATE TABLE \`${GCP_PROJECT}.${DATASET_ID}.${table_name}\`"
done

echo "Tables truncated successfully."
