#!/usr/bin/env bash

###############################################################################
# Setup the permissions and services for using Cloud Run functions.
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

check_var "GCP_PROJECT"
check_var "GCS_BUCKET"
check_var "SERVICE_ACCOUNT_NAME" "ppdb-storage-manager"
check_var "SERVICE_ACCOUNT_EMAIL" "${SERVICE_ACCOUNT_NAME}@${GCP_PROJECT}.iam.gserviceaccount.com"
check_var "GCP_REGION" "us-central1"

# Get the project number for IAM bindings
GCP_PROJECT_NUMBER="$(gcloud projects describe "${GCP_PROJECT}" --format='value(projectNumber)')"

# We need to run this script with a user account which can grant IAM roles.
gcloud config set account $(gcloud config get-value account --quiet)
gcloud config set project "${GCP_PROJECT}"

# Enable the necessary services
gcloud services enable \
  cloudfunctions.googleapis.com \
  run.googleapis.com \
  eventarc.googleapis.com \
  --project="${GCP_PROJECT}"

# Grant the cloudbuild.builds.editor IAM role to the service account
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/cloudbuild.builds.editor"

# Grant the storage.admin IAM role to the service account
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/storage.admin"

# Grant the service account the ability to use the Service Usage API
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/serviceusage.serviceUsageConsumer"

# Grant the Cloud Build service account the ability to view storage objects
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" \
  --member="serviceAccount:${GCP_PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/storage.objectViewer"

# Grant the Artifact Registry Writer role to the service account
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/artifactregistry.writer"

# Create the Artifact Registry repository if it doesn't exist
gcloud artifacts repositories create ppdb-docker-repo \
  --repository-format=docker \
  --location=us-central1 \
  --description="Container repo for PPDB images"

# Grant the Cloud Build service account the ability to build images
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" \
  --member="serviceAccount:${GCP_PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/cloudbuild.builds.builder"

echo "Setup complete. You can now submit builds using your service account."
