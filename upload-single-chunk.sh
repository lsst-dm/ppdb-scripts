#!/usr/bin/env bash

set -euxo pipefail

ppdb-replication \
    --log-level ${LOG_LEVEL} \
    upload-chunks \
    --directory ${PPDB_STAGING_DIR} \
    --bucket ${GCS_BUCKET} \
    --wait-interval 0 \
    --upload-interval 0 \
    --prefix data/tmp \
    --exit-on-empty \
    --exit-on-error
