#!/bin/bash

set -euo pipefail

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 PPDB_SCHEMA_NAME"
  exit 1
fi

# Database connection details
DB_URL="postgresql://rubin@usdf-prompt-processing-dev.slac.stanford.edu:5432/lsst-devl"
PPDB_SCHEMA_NAME="$1"
TABLE_NAME="PpdbReplicaChunk"

# Connect to the database and execute the commands
psql "$DB_URL" <<EOF
SET search_path TO '$PPDB_SCHEMA_NAME';
DELETE FROM "$PPDB_SCHEMA_NAME"."$TABLE_NAME";
EOF
