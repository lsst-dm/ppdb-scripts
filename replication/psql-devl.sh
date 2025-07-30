#!/bin/bash

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

psql "postgresql://rubin@usdf-prompt-processing-dev.slac.stanford.edu:5432/lsst-devl?options=-c%20search_path%3D${PPDB_SCHEMA_NAME}"
