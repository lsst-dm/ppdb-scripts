#!/bin/bash

# Database connection details
DB_URL="postgresql://rubin@usdf-prompt-processing-dev.slac.stanford.edu:5432/lsst-devl"
SCHEMA_NAME="ppdb_dm-49202"
TABLE_NAME="PpdbReplicaChunk"

# Connect to the database and execute the commands
psql "$DB_URL" <<EOF
SET search_path TO '$SCHEMA_NAME';
DELETE FROM "$SCHEMA_NAME"."$TABLE_NAME";
EOF
