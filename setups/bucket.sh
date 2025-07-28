#!/usr/bin/env bash

###############################################################################
# Set up the GCS bucket for PPDB service account.
###############################################################################

set -euxo pipefail

# Prevent sourcing — this script must be executed, not sourced
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  echo "Error: this script must be executed, not sourced." >&2
  return 1
fi

# Make sure the check_var function is available
if ! declare -F check_var >/dev/null; then
  echo "check_var is not defined." >&2
  return 1
fi

# Check for required environment variables
check_var "GCS_BUCKET"
check_var "GCP_PROJECT"
check_var "SERVICE_ACCOUNT_EMAIL"
check_var "REGION" "us-central1"

# Create the bucket if it does not exist
if ! gsutil ls -b "gs://${GCS_BUCKET}" >/dev/null 2>&1; then
  gsutil mb -p "${GCP_PROJECT}" -l "${REGION}" "gs://${GCS_BUCKET}"
else
  echo "Bucket ${GCS_BUCKET} already exists."
fi

# == SET IAM ROLES FOR THE BUCKET ==
gcloud storage buckets add-iam-policy-binding gs://${GCS_BUCKET} \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/storage.objectViewer"

gcloud storage buckets add-iam-policy-binding gs://${GCS_BUCKET} \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/storage.objectAdmin"

echo "Bucket ${GCS_BUCKET} setup complete with necessary IAM roles for service account ${SERVICE_ACCOUNT_EMAIL}."