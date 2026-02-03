#!/bin/bash

set -euo pipefail

ppdb-cli create-bq \
  ${PPDB_DB_URL} \
  ${PPDB_SCHEMA_NAME}.yaml \
  --project-id ${GCP_PROJECT} \
  --db-schema ${PPDB_SCHEMA_NAME} \
  --db-drop \
  --replication-dir ${PPDB_STAGING_DIR} \
  --delete-existing-dirs \
  --bucket-name ${GCS_BUCKET} \
  --dataset-id ${DATASET_ID} \
  --object-prefix data/chunks \
  --no-validate-config
