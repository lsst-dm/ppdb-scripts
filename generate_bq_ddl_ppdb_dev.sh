#!/usr/bin/env bash

generate_bq_ddl.py \
  --output-file sql/create_ppdb_dev.sql \
  --project-id $(gcloud config get-value project) \
  --dataset-name ppdb_dev
