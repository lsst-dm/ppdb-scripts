#!/usr/bin/env bash

set -euxo pipefail

# Delete objects from GCS
gcloud-rm.sh || true

# Remove local files
if [ -d "$PWD/staging" ]; then
  rm -rf "$PWD/staging" &> /dev/null
fi

# Delete records from PpdbReplicaChunk db
delete-replica-chunks.sh

# Export chunks to local files
export-chunks-test.sh

# Upload chunks to GCS
upload-chunks-test.sh
