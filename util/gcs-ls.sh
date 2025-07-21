#!/usr/bin/env bash

set -euo pipefail

if [ -z "$1" ]; then
  echo "Usage: $0 <directory_path>"
  exit 1
fi

if [ -z "${GCS_BUCKET:-}" ]; then
  echo "GCS_BUCKET is unset or empty. Please set it to your GCP project ID."
  exit 1
fi

gcloud storage ls --recursive gs://${GCS_BUCKET}/${1}
