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

ppdb-replication \
    --log-level INFO \
    upload-chunks \
    --directory ./staging/ \
    --bucket ${GCS_BUCKET} \
    --folder data/tmp \
    --exit-on-empty
