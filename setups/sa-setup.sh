#!/usr/bin/env bash

###############################################################################
# Create and configure a service account for PPDB storage management.
###############################################################################

set -euxo pipefail

# === CONFIGURATION ===

# Name of the Google Cloud project needs to be set in the environment.
if [ -z "${GCP_PROJECT:-}" ]; then
  echo "GCP_PROJECT is unset or empty. Please set it to your environment."
  exit 1
fi

# === DEFINE SERVICE ACCOUNT ===
SERVICE_ACCOUNT_NAME="ppdb-storage-manager"
SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${GCP_PROJECT}.iam.gserviceaccount.com"

# === CREATE SERVICE ACCOUNT IF NEEDED ===
if ! gcloud iam service-accounts describe "${SERVICE_ACCOUNT_EMAIL}" --quiet &>/dev/null; then
  gcloud iam service-accounts create "${SERVICE_ACCOUNT_NAME}" \
    --display-name="PPDB Storage Manager" \
    --description="Service account for managing PPDB storage and Dataflow jobs" \
    --quiet
else
  echo "Service account ${SERVICE_ACCOUNT_EMAIL} already exists."
fi

# === CREATE SERVICE ACCOUNT KEY FILE ===
SERVICE_ACCOUNT_KEY_FILE="$HOME/.gcp/${GCP_PROJECT}/keys/${SERVICE_ACCOUNT_NAME}.json"
mkdir -p "$(dirname "${SERVICE_ACCOUNT_KEY_FILE}")"

if [[ ! -f "${SERVICE_ACCOUNT_KEY_FILE}" ]]; then
  echo "Creating service account key: ${SERVICE_ACCOUNT_KEY_FILE}"
  gcloud iam service-accounts keys create "${SERVICE_ACCOUNT_KEY_FILE}" \
    --iam-account="${SERVICE_ACCOUNT_EMAIL}" \
    --quiet
else
  echo "Service account key file already exists: ${SERVICE_ACCOUNT_KEY_FILE}"
fi

echo "Service account setup completed successfully."
