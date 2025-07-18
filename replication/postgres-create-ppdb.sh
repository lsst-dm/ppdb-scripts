#!/bin/sh

set -euo pipefail

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 SCHEMA_NAME"
  exit 1
fi

# Make sure sdm_schemas dir is set
if [ -z "${SDM_SCHEMAS_DIR:-}" ]; then
  echo "ERROR: Set SDM_SCHEMAS_DIR to the location of the sdm_schemas repo."
  exit 1
fi

# Assign arguments to variables
: ${PPDB_URL:="postgresql://rubin@usdf-prompt-processing-dev.slac.stanford.edu:5432/lsst-devl"}
PPDB_SCHEMA_NAME=$1

cmd="ppdb-cli create-sql -s ${PPDB_SCHEMA_NAME} ${PPDB_URL} ${PPDB_SCHEMA_NAME}.yaml"
echo $cmd
exec $cmd
echo "Wrote ${PPDB_SCHEMA_NAME}.yaml
