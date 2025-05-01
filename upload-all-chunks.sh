#!/usr/bin/env bash

set -euxo pipefail

if [ -z "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
  echo "GOOGLE_APPLICATION_CREDENTIALS is not set. Please set it to your service account key file."
  exit 1
fi

if [ -z "$GCS_BUCKET" ]; then
  echo "BUCKET is not set. Please set it to your Google Cloud Storage bucket name."
  exit 1
fi

if [ -z "$PPDB_STAGING_DIR" ]; then
  echo "PPDB_STAGING_DIR is not set. Please set it to your PPDB staging directory."
  exit 1
fi

LOG_LEVEL="${LOG_LEVEL:-DEBUG}"

ppdb-replication \
    --log-level $LOG_LEVEL \
    upload-chunks \
    --directory $PPDB_STAGING_DIR \
    --bucket ${GCS_BUCKET} \
    --folder data/tmp \
    --exit-on-empty \
    --upload-interval 60
