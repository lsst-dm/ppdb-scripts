#!/usr/bin/env bash

set -euxo pipefail

# Export a single chunk to local parquet files
export-single-chunk.sh

# Upload a single chunk to GCS (should trigger cloud function)
upload-single-chunk.sh
