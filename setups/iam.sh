#!/usr/bin/env bash

###############################################################################
# Set up IAM roles for PPDB service account.
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
  exit 1
fi

# === CONFIGURATION ===
check_var "GCP_PROJECT"
check_var "SERVICE_ACCOUNT_EMAIL"
check_var "GCS_BUCKET"

# === SET PROJECT CONTEXT ===

# Ensure the user account is not a service account
USER_ACCOUNT="$(gcloud config get-value account)"
if [[ "$USER_ACCOUNT" == *gserviceaccount.com ]]; then
  echo "ERROR: The user account ${USER_ACCOUNT} is a service account. Please use a user account instead." >&2
  exit 1
fi

# Set the current project
gcloud config set project "${GCP_PROJECT}" --quiet
GCP_PROJECT_NUMBER="$(gcloud projects describe "${GCP_PROJECT}" --format='value(projectNumber)' --quiet)"

# === IAM BINDINGS FOR SERVICE ACCOUNT ===

# FIXME: Move Dataflow and Cloud Build setup to another script

# Allow the service account to impersonate itself
gcloud iam service-accounts add-iam-policy-binding "${SERVICE_ACCOUNT_EMAIL}" \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/iam.serviceAccountUser"

# Service Usage API
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/serviceusage.serviceUsageConsumer"

# Cloud Functions development
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" --quiet \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/cloudfunctions.developer"

# Cloud Build jobs
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/cloudbuild.builds.editor"

# Cloud storage viewer
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" \
  --member="serviceAccount:${GCP_PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/storage.objectViewer"

# Cloud storage object creation
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" \
  --member="serviceAccount:${GCP_PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/storage.objectCreator"

# Cloud storage admin
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/storage.objectAdmin"

# Cloud Build storage bucket admin
gsutil iam ch \
  "serviceAccount:${SERVICE_ACCOUNT_EMAIL}:objectAdmin" \
  "gs://${GCP_PROJECT}_cloudbuild"

# Cloud Build storage bucket object creation
gsutil iam ch \
  "serviceAccount:${SERVICE_ACCOUNT_EMAIL}:objectCreator" \
  "gs://${GCP_PROJECT}_cloudbuild"

# Cloud Build storage bucket viewer
gsutil iam ch \
  "serviceAccount:${GCP_PROJECT_NUMBER}@cloudbuild.gserviceaccount.com:objectViewer" \
  "gs://${GCP_PROJECT}_cloudbuild"

# Dataflow developer
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" --quiet \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/dataflow.developer"

# Dataflow worker
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" --quiet \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/dataflow.worker"

# Logging
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" --quiet \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/logging.logWriter"

# Networking
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" --quiet \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/compute.networkUser"

# BigQuery data editor
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" --quiet \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/bigquery.dataEditor"

# BigQuery job user
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" --quiet \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/bigquery.jobUser"

# Storage admin on the user account
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" --quiet \
  --member="user:$(gcloud config get-value account --quiet)" \
  --role="roles/storage.admin"

echo "All required IAM roles granted to ${SERVICE_ACCOUNT_EMAIL}."
