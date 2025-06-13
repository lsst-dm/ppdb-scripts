#!/usr/bin/env bash

# Print statistics about the PPDB staging directory.

(
  _staging_dir=/sdf/home/j/jeremym/rubin-user/ppdb_staging
  cd $_staging_dir

  _ready=$(find . -name ".ready" | wc -l)
  _uploaded=$(find . -name ".uploaded" | wc -l)
  _du=$(du -sh . | awk '{print $1}')
  _latest_chunk_id=$(ls -1 */*/*/* | tail -n 1)
  _last_uploaded=$(ls -1dt */*/*/*/*/.uploaded 2>/dev/null | head -n 1)

  echo "  PPDB staging directory: $_staging_dir"
  echo
  echo "  Disk usage: $_du"
  echo "  Ready chunks: $_ready"
  echo "  Uploaded chunks: $_uploaded"
  echo "  Latest chunk ID: $_latest_chunk_id"
  if [[ -n "$_last_uploaded" ]]; then
    stat --format="  Last upload: %.19y" "$_last_uploaded"
  fi
)