#!/usr/bin/env bash

set -euxo pipefail

# --log-level ${LOG_LEVEL} \

DAX_APDB_MONITOR_CONFIG="logging:lsst.dax.ppdb.metrics,lsst.dax.ppdb.bigquery._chunk_exporter,-any" \
    ppdb-replication run \
    $APDB_CONFIG_FILE $PPDB_CONFIG_FILE \
    --min-wait-time 0 \
    --max-wait-time 0 \
    --check-interval 0 \
    --exit-on-empty \
    "$@"
