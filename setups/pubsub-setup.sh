#!/usr/bin/env bash

###############################################################################
# Set up Pub/Sub for GCS eventing in PPDB.
###############################################################################

# Prevent sourcing — this script must be executed, not sourced
(return 0 2>/dev/null) && {
  echo "ERROR: This script must be executed, not sourced." >&2
  return 1 2>/dev/null || exit 1
}

set -euxo pipefail

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

# === SET PROJECT CONTEXT ===
gcloud config set project "${GCP_PROJECT}" --quiet
GCP_PROJECT_NUMBER="$(gcloud projects describe "${GCP_PROJECT}" --format='value(projectNumber)' --quiet)"

# === IAM BINDINGS FOR GCS EVENTING ===
# We have to go through some monkey business to set up GCS eventing with Pub/Sub
# in order to create the service account for it.
# FIXME: Find a better way to do this without creating a temporary bucket and topic.

echo "Granting Pub/Sub Publisher to GCS service account service-${GCP_PROJECT_NUMBER}@gs-project-accounts.iam.gserviceaccount.com"

# Temp topic and bucket names for setting up GCS eventing
TEMP_TOPIC="gcs-trigger-topic-${GCP_PROJECT}"
TEMP_BUCKET="gcs-trigger-${GCP_PROJECT}-$(uuidgen | tr '[:upper:]' '[:lower:]' | cut -d- -f1)"

# Create temp bucket
gsutil mb -p "${GCP_PROJECT}" "gs://${TEMP_BUCKET}"

# Create temp topic
gcloud pubsub topics create "${TEMP_TOPIC}" --project="${GCP_PROJECT}" --quiet || true

# Try to create the notification (triggers service account provisioning)
if ! gsutil notification create -t "${TEMP_TOPIC}" -f json "gs://${TEMP_BUCKET}"; then
  echo "First notification creation failed — checking for GCS service account..."

  GCS_SERVICE_EMAIL="service-${GCP_PROJECT_NUMBER}@gs-project-accounts.iam.gserviceaccount.com"

  # Wait until the GCS service account exists (timeout after 60 seconds)
  for i in {1..12}; do
    if gcloud iam service-accounts describe "${GCS_SERVICE_EMAIL}" --quiet &>/dev/null; then
      echo "GCS service account is now available."
      break
    fi
    echo "Waiting for GCS service account to be provisioned..."
    sleep 5
  done

  # Final check before retrying
  if ! gcloud iam service-accounts describe "${GCS_SERVICE_EMAIL}" --quiet &>/dev/null; then
    echo "ERROR: GCS service account was not provisioned in time."
    return 1
  fi

  # Retry notification creation
  if ! gsutil notification create -t "${TEMP_TOPIC}" -f json "gs://${TEMP_BUCKET}"; then
    echo "ERROR: Notification creation failed after service account was provisioned."
    return 1
  fi
fi

# Grant the actual service account permissions to publish to the topic
gcloud pubsub topics add-iam-policy-binding stage-chunk-topic \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/pubsub.publisher"

# Grant the actual service account permissions to subscribe to the topic
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" --quiet \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/pubsub.subscriber"

# Cleanup the temporary bucket and topic
gsutil notification delete "gs://${TEMP_BUCKET}"
gsutil rm -r "gs://${TEMP_BUCKET}"
gcloud pubsub topics delete "${TEMP_TOPIC}" --quiet

echo "Pub/Sub and GCS eventing setup completed successfully."
