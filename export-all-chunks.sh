#!/usr/bin/env bash

set -euxo pipefail

if [ -z "${AWS_SHARED_CREDENTIALS_FILE+x}" ]; then
  echo "AWS_CREDENTIALS_FILE is not set. Please set it to your AWS credentials file."
  exit 1
fi

if [ -z "${APDB_CONFIG_FILE+x}" ]; then
  echo "APDB_CONFIG_FILE is not set. Please set it to your APDB config file."
  exit 1
fi

if [ -z "${PPDB_CONFIG_FILE+x}" ]; then
  echo "PPDB_CONFIG_FILE is not set. Please set it to your PPDB config file."
  exit 1
fi

if [ -z "${PPDB_STAGING_DIR+x}" ]; then
  echo "PPDB_STAGING_DIR is not set. Please set it to your PPDB staging directory."
  exit 1
fi

LOG_LEVEL="${LOG_LEVEL:-DEBUG}"

ppdb-replication \
    --log-level ${LOG_LEVEL} \
    export-chunks \
    $APDB_CONFIG_FILE $PPDB_CONFIG_FILE \
    --directory $PPDB_STAGING_DIR \
    --compression snappy \
    --batch-size 1000 \
    --min-wait-time 0 \
    --max-wait-time 0 \
    --check-interval 0 \
    --exit-on-empty
