#!/usr/bin/env bash

set -euxo pipefail

###############################################################################
# Set up IAM roles for PPDB service account.
###############################################################################

# FIXME: Move GCS bucket setup and permissions to another script and also Dataflow setup should be separate.

# === CONFIGURATION ===

# Name of the Google Cloud project needs to be set in the environment.
if [ -z "${GCP_PROJECT:-}" ]; then
  echo "GCP_PROJECT is unset or empty. Please set it to your environment."
  exit 1
fi

# Email of the service account needs to be set in the environment.
if [ -z "${SERVICE_ACCOUNT_EMAIL:-}" ]; then
  echo "SERVICE_ACCOUNT_EMAIL is unset or empty. Please set it to your service account email."
  exit 1
fi

# Name of the target GCS bucket needs to be set in the environment.
if [ -z "${GCS_BUCKET:-}" ]; then
  echo "GCS_BUCKET is unset or empty. Please set it to your Google Cloud Storage bucket."
  exit 1
fi

# Set email of currently authenticated user (optional IAM binding later)
# FIXME: Shouldn't this be the service account email instead?
# It is used to assign storage.admin role at the end.
USER_EMAIL="${USER_EMAIL:-$(gcloud config get-value account --quiet)}"

# === SET PROJECT CONTEXT ===
gcloud config set project "${GCP_PROJECT}" --quiet
GCP_PROJECT_NUMBER="$(gcloud projects describe "${GCP_PROJECT}" --format='value(projectNumber)' --quiet)"

# === GRANT IAM ROLES TO SERVICE ACCOUNT ===

# Enable Cloud Functions development and impersonation
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" --quiet \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/cloudfunctions.developer"

gcloud projects add-iam-policy-binding "${GCP_PROJECT}" --quiet \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/iam.serviceAccountUser"

# Allow the service account to run Cloud Build jobs
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/cloudbuild.builds.editor"

# Give it permission to access the staging bucket
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" \
  --member="serviceAccount:${GCP_PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/storage.objectViewer"

gcloud projects add-iam-policy-binding "${GCP_PROJECT}" \
  --member="serviceAccount:${GCP_PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/storage.objectCreator"

gcloud projects add-iam-policy-binding "${GCP_PROJECT}" \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/storage.objectAdmin"

gcloud storage buckets add-iam-policy-binding gs://${GCS_BUCKET} \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/storage.objectViewer"

gcloud storage buckets add-iam-policy-binding gs://${GCS_BUCKET} \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/storage.objectAdmin"

gcloud projects add-iam-policy-binding "${GCP_PROJECT}" \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/serviceusage.serviceUsageConsumer"

gsutil iam ch \
  "serviceAccount:${SERVICE_ACCOUNT_EMAIL}:objectAdmin" \
  "gs://${GCP_PROJECT}_cloudbuild"

gsutil iam ch \
  "serviceAccount:${SERVICE_ACCOUNT_EMAIL}:objectCreator" \
  "gs://${GCP_PROJECT}_cloudbuild"

gsutil iam ch \
  "serviceAccount:${GCP_PROJECT_NUMBER}@cloudbuild.gserviceaccount.com:objectViewer" \
  "gs://${GCP_PROJECT}_cloudbuild"

# Dataflow
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" --quiet \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/dataflow.developer"
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" --quiet \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/dataflow.worker"

# GCS
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" --quiet \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/storage.objectAdmin"

# Logging
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" --quiet \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/logging.logWriter"

# Networking
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" --quiet \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/compute.networkUser"

# BigQuery
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" --quiet \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/bigquery.dataEditor"
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" --quiet \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/bigquery.jobUser"

# Storage admin
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" --quiet \
  --member="user:${USER_EMAIL}" \
  --role="roles/storage.admin"

echo "All required IAM roles granted to ${SERVICE_ACCOUNT_EMAIL}."
