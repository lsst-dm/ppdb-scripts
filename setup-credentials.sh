#!/usr/bin/env bash

GOOGLE_APPLICATION_CREDENTIALS="$HOME/.gcp/keys/ppdb-storage-manager-key.json"
if [ ! -f "${GOOGLE_APPLICATION_CREDENTIALS}" ]; then
  echo "Error: Service account key file not found: ${GOOGLE_APPLICATION_CREDENTIALS}"
else
  echo "Using service account key file: ${GOOGLE_APPLICATION_CREDENTIALS}"
  export GOOGLE_APPLICATION_CREDENTIALS
fi
