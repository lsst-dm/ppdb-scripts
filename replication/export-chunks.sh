#!/usr/bin/env bash

set -euxo pipefail

DAX_APDB_MONITOR_CONFIG="logging:lsst.dax.ppdb.metrics,lsst.dax.ppdb.export._chunk_exporter,-any" \
    ppdb-replication \
    --log-level ${LOG_LEVEL} \
    export-chunks \
    $APDB_CONFIG_FILE $PPDB_CONFIG_FILE \
    --directory $PPDB_STAGING_DIR \
    --compression snappy \
    --min-wait-time 0 \
    --max-wait-time 0 \
    --check-interval 0 \
    --exit-on-empty \
    --delete-existing \
    "$@"
