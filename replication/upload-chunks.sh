#!/usr/bin/env bash

set -euxo pipefail

ppdb-replication \
    --log-level ${LOG_LEVEL} \
    upload-chunks \
    --bucket ${GCS_BUCKET} \
    --dataset ${GCP_PROJECT}:${DATASET_ID} \
    --wait-interval 0 \
    --upload-interval 0 \
    --prefix data \
    --exit-on-empty \
    --exit-on-error \
    ${PPDB_CONFIG_FILE}
