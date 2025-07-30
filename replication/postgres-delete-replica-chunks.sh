#!/bin/bash

set -euo pipefail

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

check_var "PPDB_SCHEMA_NAME"

# Y/N confirmation
read -p "Are you sure you want to delete all rows from \"$PPDB_SCHEMA_NAME.PpdbReplicaChunk\"? [y/N] " confirm
case "$confirm" in
    [yY]) ;;
    *) echo "Aborted."; exit 1 ;;
esac

# Database connection details
DB_URL="postgresql://rubin@usdf-prompt-processing-dev.slac.stanford.edu:5432/lsst-devl"
TABLE_NAME="PpdbReplicaChunk"

# Connect to the database and execute the commands
psql "$DB_URL" <<EOF
SET search_path TO '$PPDB_SCHEMA_NAME';
DELETE FROM "$PPDB_SCHEMA_NAME"."$TABLE_NAME";
EOF
