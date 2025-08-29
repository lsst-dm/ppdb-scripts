#!/usr/bin/env bash

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

# Ensure the user account is not a service account
USER_ACCOUNT="$(gcloud config get-value account)"
if [[ "$USER_ACCOUNT" == *gserviceaccount.com ]]; then
  echo "ERROR: The user account ${USER_ACCOUNT} is a service account. Please use a user account instead." >&2
  exit 1
fi

check_var "GCP_PROJECT"

SERVICE_ACCOUNT_NAME="cnpg-gke-deployer"
SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${GCP_PROJECT}.iam.gserviceaccount.com"

# Enable necessary APIs
gcloud services enable \
  container.googleapis.com \
  compute.googleapis.com \
  iam.googleapis.com

echo "Creating service account ${SERVICE_ACCOUNT_NAME}..."
if gcloud iam service-accounts describe "$SERVICE_ACCOUNT_EMAIL" >/dev/null 2>&1; then
  echo "Service account already exists: ${SERVICE_ACCOUNT_EMAIL}"
else
  gcloud iam service-accounts create "$SERVICE_ACCOUNT_NAME" \
    --description="Service account for deploying CNPG on GKE" \
    --display-name="CNPG GKE Deployer"
fi

echo "Assigning IAM roles to service account..."

# Needed to create and manage GKE clusters
gcloud projects add-iam-policy-binding ${GCP_PROJECT} \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/container.admin"

# Needed to create firewall rules, static IPs, load balancers, routes
gcloud projects add-iam-policy-binding ${GCP_PROJECT} \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/compute.networkAdmin"

# Needed to assign IAM roles to service accounts (optional if not managing other SAs)
gcloud projects add-iam-policy-binding ${GCP_PROJECT} \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/iam.serviceAccountUser"
