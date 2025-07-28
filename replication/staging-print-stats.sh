#!/usr/bin/env bash

# Print statistics about the PPDB staging directory.

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

check_var "PPDB_STAGING_DIR"

(
  cd ${PPDB_STAGING_DIR}

  _ready=$(find . -name ".ready" | wc -l)
  _uploaded=$(find . -name ".uploaded" | wc -l)
  _du=$(du -sh . | awk '{print $1}')
  _latest_chunk_id=$(ls -1 */*/*/* | tail -n 1)
  _last_uploaded=$(ls -1dt */*/*/*/*/.uploaded 2>/dev/null | head -n 1)

  echo "  PPDB staging directory: ${PPDB_STAGING_DIR}"
  echo
  echo "  Disk usage: $_du"
  echo "  Ready chunks: $_ready"
  echo "  Uploaded chunks: $_uploaded"
  echo "  Latest chunk ID: $_latest_chunk_id"
  if [[ -n "$_last_uploaded" ]]; then
    stat --format="  Last upload: %.19y" "$_last_uploaded"
  fi
)