#!/usr/bin/env bash

# Usage: ./bq-copy-dataset.sh source_project.source_dataset target_project.target_dataset

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 source_project.source_dataset target_project.target_dataset"
  exit 1
fi

SRC="$1"
DST="$2"

SRC_PROJECT="${SRC%%.*}"
SRC_DATASET="${SRC#*.}"
DST_PROJECT="${DST%%.*}"
DST_DATASET="${DST#*.}"

# List tables in the source dataset
tables=$(bq ls --project_id="$SRC_PROJECT" "$SRC_DATASET" | awk 'NR>2 {print $1}')

for table in $tables; do
  echo "Copying $SRC_PROJECT.$SRC_DATASET.$table to $DST_PROJECT.$DST_DATASET.$table"
  bq cp -f \
    "$SRC_PROJECT:$SRC_DATASET.$table" \
    "$DST_PROJECT:$DST_DATASET.$table"
done