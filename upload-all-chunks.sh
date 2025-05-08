#!/usr/bin/env bash

set -euxo pipefail

ppdb-replication \
    --log-level ${LOG_LEVEL} \
    upload-chunks \
    --directory ${PPDB_STAGING_DIR} \
    --bucket ${GCS_BUCKET} \
    --prefix data/tmp \
    --exit-on-empty \
    --upload-interval 60
