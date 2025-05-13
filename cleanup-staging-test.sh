#!/usr/bin/env bash

set -euxo pipefail

# Remove staging files from GCS
gcs-rm.sh

# Truncate tables in BigQuery
truncate-tables.sh

# Delete rows from replica chunks database
delete-replica-chunks.sh ppdb_dm50040

# Delete local staging directory
staging_dir=$PWD/staging
if [ -d "$staging_dir" ]; then
  rm -rf "$staging_dir/*"
else
    echo "Staging directory $staging_dir does not exist."
    exit 1
fi
echo "Staging directory removed."
