#!/usr/bin/env bash

###############################################################################
# Copies all tables from source dataset to target dataset.
# The target dataset is created if it doesn't exist.
# Only copies DiaObject, DiaSource, and DiaForcedSource tables.
# Existing tables in the target dataset are not overwritten and will be
# skipped.
#
# Usage: ./bq-copy-dataset.sh src_prj:src_dataset target_prj:target_dataset
#
# It isn't recommended to use this for copying very large datasets from one
# project to another.
###############################################################################

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 source_project.source_dataset target_project.target_dataset"
  exit 1
fi

SRC="$1"
DST="$2"

# Split into project and dataset components.
# These must use ':' as the separator, not '.'.
SRC_PROJECT="${SRC%%:*}"
SRC_DATASET="${SRC#*:}"
DST_PROJECT="${DST%%:*}"
DST_DATASET="${DST#*:}"

if [[ -z "$SRC_PROJECT" || -z "$SRC_DATASET" || -z "$DST_PROJECT" || -z "$DST_DATASET" ]]; then
  echo "ERROR: Invalid source or target dataset format. Expected format 'project:dataset'" >&2
  exit 1
fi

echo "Copying dataset from $SRC_PROJECT.$SRC_DATASET to $DST_PROJECT.$DST_DATASET"

# Check if target dataset exists, create if it doesn't
echo "Checking if target dataset $DST_PROJECT:$DST_DATASET exists..."
if ! bq ls "$DST_PROJECT:$DST_DATASET" &>/dev/null; then
  echo "Target dataset does not exist. Creating $DST_PROJECT:$DST_DATASET ..."
  bq mk --dataset "$DST_PROJECT:$DST_DATASET"
  echo "Target dataset created successfully."
else
  echo "Target dataset already exists."
fi

tables=$(bq ls "$SRC" | awk 'NR>2 {print $1}')

status=$?
if [ $status -ne 0 ]; then
  echo "ERROR: Failed to list tables in dataset '$SRC'" >&2
  echo "$output" >&2
  exit $status
fi

echo "Tables to copy:"
echo "$tables"

for table in $tables; do
  # Only copy specific tables.
  case "$table" in
  "DiaObject"|"DiaSource"|"DiaForcedSource")
    :  # Copy these tables.
    ;;
  *)
    continue  # Skip other tables.
    ;;
  esac
  # Check if target table already exists and skip if it does.
  if bq show "$DST_PROJECT:$DST_DATASET.$table" &>/dev/null; then
    echo "Table $DST_PROJECT.$DST_DATASET.$table already exists. Skipping..."
  # Copy table with -f to suppress prompts. We already checked above that the
  # table does not exist.
  else
    echo "Copying $SRC_PROJECT:$SRC_DATASET.$table to $DST_PROJECT:$DST_DATASET.$table"
    bq cp -sync=false --force "$SRC_PROJECT:$SRC_DATASET.$table" "$DST_PROJECT:$DST_DATASET.$table"
  fi
done

echo "Dataset copy completed."
