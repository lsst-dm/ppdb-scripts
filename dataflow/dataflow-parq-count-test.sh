#!/usr/bin/env bash

set -euxo pipefail

if [ -z "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]; then
  echo "GOOGLE_APPLICATION_CREDENTIALS is unset or empty. Please set it to your service account key file."
  exit 1
fi

if [ -z "${PROJECT_ID:-}" ]; then
  echo "PROJECT_ID is unset or empty. Please set it to your Google Cloud project ID."
  exit 1
fi

if [ -z "${GCS_BUCKET:-}" ]; then
  echo "BUCKET is unset or empty. Please set it to your Google Cloud Storage bucket name."
  exit 1
fi

if [ -z "${GCP_REGION:-}" ]; then
  echo "GCP_REGION is unset or empty. Please set it to your Google Cloud region."
  exit 1
fi

if [ -z "${SERVICE_ACCOUNT_EMAIL:-}" ]; then
  echo "SERVICE_ACCOUNT_EMAIL is unset or empty. Please set it to your Google Cloud service account email."
  exit 1
fi

python parq_count_beam_job.py \
  --runner=DataflowRunner \
  --project="${PROJECT_ID}" \
  --region="${GCP_REGION}" \
  --temp_location="gs://${GCS_BUCKET}/dataflow/temp" \
  --staging_location="gs://${GCS_BUCKET}/dataflow/staging" \
  --service_account_email="${SERVICE_ACCOUNT_EMAIL}" \
  --network=default \
  --input_path="gs://${GCS_BUCKET}/data/tmp/2025/04/23/1737056400/DiaSource.parquet"
