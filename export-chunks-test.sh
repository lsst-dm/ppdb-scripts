#!/usr/bin/env bash
APDB_CONFIG=s3://rubin-pp-dev-users/apdb_config/cassandra/pp_apdb_lsstcomcamsim-dev.py
PPDB_CONFIG=$PWD/ppdb_dm-49202.yaml
export AWS_SHARED_CREDENTIALS_FILE=$HOME/.aws/aws-credentials.ini
SDM_SCHEMAS_DIR=../sdm_schemas ppdb-replication \
    --log-level INFO \
    export-chunks \
    $APDB_CONFIG $PPDB_CONFIG \
    --directory $PWD/staging \
    --compression snappy \
    --batch-size 1000 \
    --min-wait-time 0 \
    --max-wait-time 0 \
    --check-interval 9 \
    --exit-on-empty \
    --single # DEBUG
