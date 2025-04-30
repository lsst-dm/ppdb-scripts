#!/usr/bin/env bash

set -euxo pipefail

if [ -z "${GCP_PROJECT+x}" ]; then
  echo "GCP_PROJECT is not set. Please set it to your GCP project ID."
  exit 1
fi

if [ -z "${DATASET_ID+x}" ]; then
  echo "DATASET_ID is not set. Please set it to your BigQuery dataset name."
  exit 1
fi

SNAPSHOT_DATASET_ID="${DATASET_ID}_snapshot"

# Create the snapshot dataset if it does not exist
if ! bq --project_id="$GCP_PROJECT" show "$SNAPSHOT_DATASET_ID" >/dev/null 2>&1; then
  echo "Snapshot dataset $SNAPSHOT_DATASET_ID does not exist. Creating it..."
  bq --project_id="$GCP_PROJECT" mk "$SNAPSHOT_DATASET_ID"
  echo "Snapshot dataset $SNAPSHOT_DATASET_ID created successfully."
fi

# Get the current timestamp
TIMESTAMP=$(date -u +"%Y%m%d%H%M%S")

# List all tables in the dataset
readarray -t TABLES < <(bq ls --project_id="$GCP_PROJECT" --format=prettyjson "$DATASET_ID" | jq -r '.[].tableReference.tableId')

# Create snapshots for each table
for TABLE in "${TABLES[@]}"; do
  SNAPSHOT_TABLE="${TABLE}_${TIMESTAMP}"

  # Check if the snapshot already exists
  if bq --project_id="$GCP_PROJECT" show "${SNAPSHOT_DATASET_ID}.${SNAPSHOT_TABLE}" >/dev/null 2>&1; then
    echo "Snapshot $SNAPSHOT_TABLE already exists. Skipping..."
    continue
  fi

  echo "Creating snapshot for table: $TABLE -> $SNAPSHOT_TABLE"
  bq cp --project_id="$GCP_PROJECT" \
    --no_clobber \
    "${GCP_PROJECT}:${DATASET_ID}.${TABLE}" \
    "${GCP_PROJECT}:${SNAPSHOT_DATASET_ID}.${SNAPSHOT_TABLE}"
done

echo "Snapshots created successfully."
