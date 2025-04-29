#!/usr/bin/env bash

set -e -x
set -o pipefail

if [ -z "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
  echo "GOOGLE_APPLICATION_CREDENTIALS is not set. Please set it to your service account key file."
  exit 1
fi

if [ -z "$SERVICE_ACCOUNT_EMAIL" ]; then
  echo "SERVICE_ACCOUNT_EMAIL is not set. Please set it to your Google Cloud service account email."
  exit 1
fi

python -m apache_beam.examples.wordcount \
  --runner=DataflowRunner \
  --project=ppdb-dev-438721 \
  --region=us-central1 \
  --temp_location=gs://rubin-ppdb-test-bucket-1/dataflow/temp \
  --staging_location=gs://rubin-ppdb-test-bucket-1/dataflow/staging \
  --output gs://rubin-ppdb-test-bucket-1/dataflow/test-output.txt \
  --service_account_email="${SERVICE_ACCOUNT_EMAIL}" \
  --network=default
