#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <DATAFLOW_JOB_ID>" >&2
  exit 1
fi

GCP_PROJECT="${GCP_PROJECT:-ppdb-prod}"
GCP_REGION="${GCP_REGION:-us-central1}"

JOB_ID="$1"

PROJECT_NUMBER="$(gcloud projects describe "${GCP_PROJECT}" \
  --format='value(projectNumber)')"

BUCKET="gs://dataflow-staging-${GCP_REGION}-${PROJECT_NUMBER}"
LOG_PREFIX="${BUCKET}/staging/template_launches/${JOB_ID}/console_logs"

if ! gsutil ls "${LOG_PREFIX}/" >/dev/null 2>&1; then
  echo "No Dataflow launcher console logs found for job:" >&2
  echo "  ${JOB_ID}" >&2
  echo "Expected location:" >&2
  echo "  ${LOG_PREFIX}/" >&2
  exit 2
fi

gsutil ls "${LOG_PREFIX}/" | sort | while read -r obj; do
  echo "===== ${obj} ====="
  gsutil cat "${obj}"
  echo
done

