#!/usr/bin/env bash

set -euo pipefail

if [ -z "$1" ]; then
  echo "Usage: $0 <directory_path>"
  exit 1
fi

read -p "Are you sure you want to delete all contents under data/tmp/? [Y/N] " confirm
if [[ "$confirm" == [yY] ]]; then
    gcloud storage rm --recursive gs://${GCP_BUCKET}/${1}
else
    echo "Aborted."
fi
