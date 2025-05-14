#!/usr/bin/env bash

set -euxo pipefail

read -p "Are you sure you want to clean up staging? [y/N] " confirm
case "$confirm" in
    [yY]) ;;
    *) echo "Aborted."; exit 1 ;;
esac

# Remove staging files from GCS
gcs-rm.sh

# Truncate tables in BigQuery
bq-truncate-tables.sh

# Delete rows from replica chunks database
postgres-delete-replica-chunks.sh ppdb_dm50040

# Delete local staging directory
staging_dir=$PWD/staging
if [ -d "$staging_dir" ]; then
  rm -rf "$staging_dir/*"
else
    echo "Staging directory $staging_dir does not exist."
    exit 1
fi
echo "Staging directory removed."
