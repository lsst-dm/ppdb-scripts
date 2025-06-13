#!/usr/bin/env bash

set -euxo pipefail

if [ -z "$1" ]; then
  echo "Usage: $0 <dataset_name>"
  exit 1
fi

DATASET_NAME=${1}

if [[ ! -d "sql/${DATASET_NAME}" ]]; then
  echo "Directory sql/${DATASET_NAME} does not exist."
  exit 1
fi

for sql_file in $(ls sql/${DATASET_NAME}/*.sql); do
  echo "Running SQL file: $sql_file"
  echo $sql_file
  bq query --use_legacy_sql=false < "$sql_file"
done
echo "All SQL files executed successfully."