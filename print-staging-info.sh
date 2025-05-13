#!/usr/bin/env bash

(
  _staging_dir=/sdf/home/j/jeremym/rubin-user/ppdb_staging
  cd $_staging_dir

  _ready=$(find . -name ".ready" | wc -l)
  _uploaded=$(find . -name ".uploaded" | wc -l)
  _du=$(du -sh . | awk '{print $1}')
  _last_chunk_id=$(ls -1 */*/*/* | tail -n 1)

  echo "  PPDB staging directory: $_staging_dir"
  echo
  echo "  Disk usage: $_du"
  echo "  Ready chunks: $_ready"
  echo "  Uploaded chunks: $_uploaded"
  echo "  Last chunk ID: $_last_chunk_id"

)