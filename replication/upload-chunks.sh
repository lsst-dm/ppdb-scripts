#!/usr/bin/env bash

set -euxo pipefail

DAX_APDB_MONITOR_CONFIG="logging:lsst.dax.ppdb.metrics,lsst.dax.ppdb.bigquery._chunk_uploader,-any" \
    ppdb-replication \
    --log-level ${LOG_LEVEL} \
    upload-chunks \
    --wait-interval 0 \
    --upload-interval 0 \
    --exit-on-empty \
    --exit-on-error \
    ${PPDB_CONFIG_FILE}
