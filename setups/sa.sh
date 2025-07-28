#!/usr/bin/env bash

###############################################################################
# Create and configure a service account for PPDB storage management.
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
SERVICE_ACCOUNT_KEY_FILE="$HOME/.gcp/${GCP_PROJECT}/keys/${SERVICE_ACCOUNT_NAME}-key.json"
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
