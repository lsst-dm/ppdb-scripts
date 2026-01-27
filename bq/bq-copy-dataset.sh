#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 source_project:source_dataset target_project:target_dataset"
  exit 1
fi

SRC="$1"
DST="$2"

SRC_PROJECT="${SRC%%:*}"
SRC_DATASET="${SRC#*:}"
DST_PROJECT="${DST%%:*}"
DST_DATASET="${DST#*:}"

echo "Copying dataset from ${SRC_PROJECT}:${SRC_DATASET} to ${DST_PROJECT}:${DST_DATASET}"

# Correct dataset existence check
echo "Checking if target dataset ${DST_PROJECT}:${DST_DATASET} exists..."
if ! bq show "${DST_PROJECT}:${DST_DATASET}" >/dev/null 2>&1; then
  echo "Target dataset does not exist. Creating ${DST_PROJECT}:${DST_DATASET} ..."
  bq mk --dataset "${DST_PROJECT}:${DST_DATASET}"
else
  echo "Target dataset already exists."
fi

# List tables (simple, works)
tables=$(bq ls "${SRC_PROJECT}:${SRC_DATASET}" | awk 'NR>2 {print $1}')

for table in $tables; do
  case "$table" in
    DiaObject|DiaSource|DiaForcedSource)
      ;;
    *)
      continue
      ;;
  esac

  if bq show "${DST_PROJECT}:${DST_DATASET}.${table}" >/dev/null 2>&1; then
    echo "Table ${DST_PROJECT}:${DST_DATASET}.${table} already exists. Skipping..."
  else
    echo "Copying ${SRC_PROJECT}:${SRC_DATASET}.${table} to ${DST_PROJECT}:${DST_DATASET}.${table}"
    bq cp -f \
      "${SRC_PROJECT}:${SRC_DATASET}.${table}" \
      "${DST_PROJECT}:${DST_DATASET}.${table}"
  fi
done

echo "Dataset copy completed."
