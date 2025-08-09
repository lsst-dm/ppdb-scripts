#!/usr/bin/env bash

# Export a single chunk
export-chunks.sh --single

# Upload chunks to GCS
upload-chunks.sh
