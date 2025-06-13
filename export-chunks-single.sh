#!/usr/bin/env bash

set -euxo pipefail

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
    --exit-on-empty \
    --single
