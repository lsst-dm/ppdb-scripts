#!/usr/bin/env bash

set -euxo pipefail

# Prevent sourcing — this script must be executed, not sourced
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  echo "Error: this script must be executed, not sourced." >&2
  return 1
fi

# Make sure the check_var function is available
if ! declare -F check_var >/dev/null; then
  echo "check_var is not defined." >&2
  exit 1
fi

check_var "LOG_LEVEL" "INFO"
check_var "APDB_CONFIG_FILE"
check_var "PPDB_CONFIG_FILE"
check_var "PPDB_STAGING_DIR"

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
