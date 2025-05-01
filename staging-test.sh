#!/usr/bin/env bash

set -euxo pipefail

# Cleanup previous test data
cleanup-staging-test.sh

# Export chunks to local files
export-all-chunks.sh

# Upload chunks to GCS
upload-all-chunks.sh
