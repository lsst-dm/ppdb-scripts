#!/usr/bin/env bash

set -euxo pipefail

# Ensure PPDB_STAGING_DIR is set and not empty
if [ -z "${PPDB_STAGING_DIR+x}" ] || [ -z "$PPDB_STAGING_DIR" ]; then
  echo "PPDB_STAGING_DIR is not set or is empty. Please set it to your staging directory."
  exit 1
fi

# Ensure the last part of the path is "staging"
if [ "$(basename "$PPDB_STAGING_DIR")" != "staging" ]; then
  echo "PPDB_STAGING_DIR must end with a directory named 'staging'."
  exit 1
fi

# Proceed with cleanup
if [ -d "$PPDB_STAGING_DIR" ]; then
  rm -rf "$PPDB_STAGING_DIR"/*
  echo "Staging directory cleaned up: $PPDB_STAGING_DIR"
else
  echo "Staging directory $PPDB_STAGING_DIR does not exist."
  exit 1
fi