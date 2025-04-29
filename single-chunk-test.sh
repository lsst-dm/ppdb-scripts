#!/usr/bin/env bash

set -e -x
set -o pipefail

# Export a single chunk to local parquet files
export-chunks-test.sh

# Upload a single chunk to GCS (should trigger cloud function)
upload-chunks-test.sh
