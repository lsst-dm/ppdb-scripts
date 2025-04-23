#!/usr/bin/env bash

export GOOGLE_APPLICATION_CREDENTIALS="$PWD/ppdb-dev-438721-9c8a37cf43d9.json"

ppdb-replication \
    --log-level DEBUG \
    upload-chunks \
    --directory ./staging/ \
    --bucket rubin-ppdb-test-bucket-1 \
    --folder data/tmp \
    --exit-on-empty
