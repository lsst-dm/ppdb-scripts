#!/usr/bin/env bash

export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.gcp/keys/ppdb-storage-manager-key.json"
export SERVICE_ACCOUNT=ppdb-storage-manager
export PROJECT_ID=ppdb-dev-438721

python -m apache_beam.examples.wordcount \
  --runner=DataflowRunner \
  --project=ppdb-dev-438721 \
  --region=us-central1 \
  --temp_location=gs://rubin-ppdb-test-bucket-1/dataflow/temp \
  --staging_location=gs://rubin-ppdb-test-bucket-1/dataflow/staging \
  --output gs://rubin-ppdb-test-bucket-1/dataflow/test-output.txt \
  --service_account_email="${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --network=default
