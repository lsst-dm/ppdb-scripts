#!/usr/bin/env bash
set -euxo pipefail

if [ -z "${GCP_PROJECT:-}" ]; then
  GCP_PROJECT="$(gcloud config get-value project --quiet)"
fi

if [ -z "${GCS_BUCKET:-}" ]; then
  echo "GCS_BUCKET is unset or empty. Please set it to your Google Cloud Storage bucket name."
  exit 1
fi

if [ -z "${SERVICE_ACCOUNT_NAME:-}" ]; then
  SERVICE_ACCOUNT_NAME="ppdb-storage-manager"
fi

if [ -z "${SERVICE_ACCOUNT_EMAIL:-}" ]; then
  SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${GCP_PROJECT}.iam.gserviceaccount.com"
fi

if [ -z "${REGION:-}" ]; then
  REGION="us-central1"
fi

# Get the project number for IAM bindings
GCP_PROJECT_NUMBER="$(gcloud projects describe "${GCP_PROJECT}" --format='value(projectNumber)')"

# We need to run this script with a user account which can grant IAM roles.
gcloud config set account jeremym@lsst.cloud
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
  --member="serviceAccount:${SERVICE_ACCOUNT_NAME}@ppdb-prod.iam.gserviceaccount.com" \
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

# Enable uniform bucket-level access to respect project IAM
gsutil uniformbucketlevelaccess set on "${BUCKET_NAME}"

# Grant the service access to the GCS bucket
gsutil iam ch \
  "serviceAccount:ppdb-storage-manager@${GCP_PROJECT}.iam.gserviceaccount.com:objectCreator" \
  gs://${GCS_BUCKET}

# Switch to the service account for performing the deployment
gcloud auth activate-service-account --key-file="$HOME/.gcp/keys/${GCP_PROJECT}/${SERVICE_ACCOUNT_NAME}.json"
gcloud config set project "${GCP_PROJECT}"

echo "Setup complete. You can now submit builds using your service account."
