#!/usr/bin/env bash

python -m apache_beam.examples.wordcount \
  --runner=DataflowRunner \
  --project=ppdb-dev-438721 \
  --region=us-central1 \
  --temp_location=gs://rubin-ppdb-test-bucket-1/dataflow/temp \
  --staging_location=gs://rubin-ppdb-test-bucket-1/dataflow/staging \
  --output gs://rubin-ppdb-test-bucket-1/dataflow/test-output.txt
