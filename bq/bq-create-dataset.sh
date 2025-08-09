#!/usr/bin/env bash
set -euxo pipefail

# ---- config / env ----
: "${DATASET_ID:?Environment variable DATASET_ID is required}"
: "${GCP_PROJECT:?Environment variable GCP_PROJECT is required}"
LOCATION="${LOCATION:-US}"  # override if needed (e.g., US, EU, us-central1)

# ---- deps ----
command -v bq >/dev/null 2>&1 || { echo "Error: bq CLI not found in PATH." >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "Error: jq is required." >&2; exit 1; }

# ---- args ----
if [ -z "${1:-}" ]; then
  echo "Usage: $0 <dir>"
  exit 1
fi
sql_dir="$1"
[ -d "$sql_dir" ] || { echo "Directory '$sql_dir' does not exist."; exit 1; }

# ---- dataset guard ----
if bq --project_id="${GCP_PROJECT}" --location="${LOCATION}" show --format=none "${GCP_PROJECT}:${DATASET_ID}" >/dev/null 2>&1; then
  echo "Error: Dataset '${GCP_PROJECT}:${DATASET_ID}' already exists." >&2
  exit 1
fi

# ---- create dataset ----
bq --project_id="${GCP_PROJECT}" --location="${LOCATION}" mk --dataset "${DATASET_ID}"

# ---- tables to create ----
tables=(DiaObject DiaSource DiaForcedSource)

# ---- create primary tables from DDL files ----
for table_name in "${tables[@]}"; do
  sql_file="${sql_dir}/${table_name}.sql"
  [ -f "$sql_file" ] || { echo "Missing SQL file: $sql_file"; exit 1; }

  # Ensure DDL is fully-qualified or pass defaults below
  bq --project_id="${GCP_PROJECT}" --location="${LOCATION}" query --use_legacy_sql=false --quiet < "$sql_file"
done

# ---- create staging tables with extra REQUIRED column ----
cleanup_files=()
trap 'for f in "${cleanup_files[@]:-}"; do [ -f "$f" ] && rm -f "$f"; done' EXIT

for table in "${tables[@]}"; do
  staging_table_name="_${table}_staging"

  # Read base schema
  base_json="$(bq --project_id="${GCP_PROJECT}" --location="${LOCATION}" show --format=json "${GCP_PROJECT}:${DATASET_ID}.${table}")"
  schema_json="$(echo "${base_json}" | jq -c '.schema.fields')"

  # Append replicaChunkId
  updated_schema="$(echo "${schema_json}" \
    | jq -c '. + [{"name":"replicaChunkId","type":"INTEGER","mode":"REQUIRED","description":"Chunk ID for staging"}]')"

  schema_file="$(mktemp)"
  cleanup_files+=("$schema_file")
  echo "${updated_schema}" > "${schema_file}"

  # Create staging table
  bq --project_id="${GCP_PROJECT}" --location="${LOCATION}" mk --table --schema="${schema_file}" \
     "${GCP_PROJECT}:${DATASET_ID}.${staging_table_name}"
done

echo "All tables created in dataset: ${GCP_PROJECT}:${DATASET_ID}"
