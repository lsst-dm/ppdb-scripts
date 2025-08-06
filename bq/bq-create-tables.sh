#!/usr/bin/env bash
set -euo pipefail

if [ -z "${1:-}" ]; then
  echo "Usage: $0 <dir>"
  echo "Please provide the directory containing SQL files."
  exit 1
fi

sql_dir="$1"

if [ ! -d "$sql_dir" ]; then
  echo "Directory '$sql_dir' does not exist."
  exit 1
fi

if [ -z "${GCP_PROJECT:-}" ]; then
  echo "Environment variable GCP_PROJECT is not set."
  exit 1
fi

if [ -z "${DATASET_ID:-}" ]; then
  echo "Environment variable DATASET_ID is not set."
  exit 1
fi

tables=(DiaObject DiaSource DiaForcedSource)

# Primary tables from SQL files
for table_name in "${tables[@]}"; do
  sql_file="${sql_dir}/${table_name}.sql"
  if [ ! -f "$sql_file" ]; then
    echo "SQL file for $table_name does not exist: $sql_file"
    exit 1
  fi

  echo "Dropping table (if exists): $table_name"
  bq rm -f -t "${GCP_PROJECT}:${DATASET_ID}.${table_name}"

  echo "Creating table: $table_name"
  bq query --use_legacy_sql=false < "$sql_file"
done

for table in "${tables[@]}"; do
  staging_table_name="_${table}_staging"
  echo "Creating staging table for $table: $staging_table_name"

  # Drop staging table if it exists
  bq rm -f -t "${GCP_PROJECT}:${DATASET_ID}.${staging_table_name}" >/dev/null 2>&1 || true

  # Get the schema of the original table (JSON format)
  schema_json=$(bq show --format=json "${GCP_PROJECT}:${DATASET_ID}.${table}" | jq '.schema.fields')

  # Add the extra NOT NULL column manually
  updated_schema=$(echo "$schema_json" | \
    jq '. += [{"name": "replicaChunkId", "type": "INTEGER", "mode": "REQUIRED", "description": "Chunk ID for staging"}]')

  # Save schema to a temporary file
  schema_file=$(mktemp)
  echo "$updated_schema" > "$schema_file"

  # Create the table with the explicit schema
  bq mk --table --schema="$schema_file" "${GCP_PROJECT}:${DATASET_ID}.${staging_table_name}"

  echo "Staging table $staging_table_name created with replicaChunkId NOT NULL."
done

echo "All tables created successfully in dataset: ${GCP_PROJECT}.${DATASET_ID}"
