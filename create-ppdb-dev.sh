#!/usr/bin/env bash

set -euxo pipefail

for sql_file in sql/ppdb_dev/*.sql; do
  echo "Running SQL file: $sql_file"
  bq query --use_legacy_sql=false < "$sql_file"
done
echo "All SQL files executed successfully."