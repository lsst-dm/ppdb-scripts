#!/usr/bin/env bash

set -euxo pipefail

# Ensure GCP_PROJECT is set
if [ -z "${GCP_PROJECT+x}" ]; then
  echo "GCP_PROJECT is not set. Please set it to your GCP project ID."
  exit 1
fi

# Ensure DATASET_ID is set
if [ -z "${DATASET_ID+x}" ]; then
  echo "DATASET_ID is not set. Please set it to your BigQuery dataset name."
  exit 1
fi

# Ensure a snapshot date is provided as a command-line argument
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <snapshot_date>"
  echo "Example: $0 20250430234459"
  exit 1
fi

SNAPSHOT_DATE="$1"
SNAPSHOT_DATASET_ID="${DATASET_ID}_snapshot"

# List all snapshot tables for the given date
readarray -t SNAPSHOT_TABLES < <(bq ls --project_id="$GCP_PROJECT" --format=prettyjson "$SNAPSHOT_DATASET_ID" | jq -r ".[] | select(.tableReference.tableId | endswith(\"_${SNAPSHOT_DATE}\")) | .tableReference.tableId")

if [ "${#SNAPSHOT_TABLES[@]}" -eq 0 ]; then
  echo "No snapshots found for date $SNAPSHOT_DATE in dataset $SNAPSHOT_DATASET_ID."
  exit 1
fi

# Restore each snapshot by replacing the corresponding table
for SNAPSHOT_TABLE in "${SNAPSHOT_TABLES[@]}"; do
  # Extract the original table name by removing the snapshot date suffix
  ORIGINAL_TABLE="${SNAPSHOT_TABLE%_${SNAPSHOT_DATE}}"

  echo "Restoring snapshot $SNAPSHOT_TABLE to table $ORIGINAL_TABLE..."

  # Replace the original table with the snapshot
  bq cp --project_id="$GCP_PROJECT" \
    --force \
    "${GCP_PROJECT}:${SNAPSHOT_DATASET_ID}.${SNAPSHOT_TABLE}" \
    "${GCP_PROJECT}:${DATASET_ID}.${ORIGINAL_TABLE}"

  if [ $? -eq 0 ]; then
    echo "Successfully restored $ORIGINAL_TABLE from snapshot $SNAPSHOT_TABLE."
  else
    echo "Failed to restore $ORIGINAL_TABLE from snapshot $SNAPSHOT_TABLE."
    exit 1
  fi
done

echo "All snapshots restored successfully."