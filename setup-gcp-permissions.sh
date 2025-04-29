#!/usr/bin/env bash

set -euo pipefail
set -x

# === CONFIGURATION ===
GCP_PROJECT="${GCP_PROJECT:-ppdb-dev-438721}"
GCP_PROJECT_NUMBER="$(gcloud projects describe ${GCP_PROJECT} --format='value(projectNumber)')"
SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_EMAIL:-ppdb-storage-manager@${GCP_PROJECT}.iam.gserviceaccount.com}"
USER_EMAIL="${USER_EMAIL:-$(gcloud config get-value account)}"

# === PREVENT SCRIPT EXECUTION AS A SERVICE ACCOUNT ===
if [[ "${USER_EMAIL}" == *gserviceaccount.com ]]; then
  echo "ERROR: This script must be run as a user account, not a service account."
  echo "Current account: ${USER_EMAIL}"
  echo "Run 'gcloud auth login' to switch."
  exit 1
fi

# === IAM BINDINGS FOR GCS EVENTING ===
echo "Granting Pub/Sub Publisher to GCS service account service-${GCP_PROJECT_NUMBER}@gs-project-accounts.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding "${GCP_PROJECT}" \
  --member="serviceAccount:service-${GCP_PROJECT_NUMBER}@gs-project-accounts.iam.gserviceaccount.com" \
  --role="roles/pubsub.publisher"

# === IAM BINDINGS FOR SERVICE ACCOUNT ===
echo "Granting roles to ${SERVICE_ACCOUNT_EMAIL}"

# Cloud Functions deployment and execution
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/cloudfunctions.developer"
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/iam.serviceAccountUser"

# Dataflow job creation and worker execution
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/dataflow.developer"
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/dataflow.worker"

# GCS access
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/storage.objectAdmin"

# Logging
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/logging.logWriter"

# Networking
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/compute.networkUser"

# BigQuery access
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/bigquery.dataEditor"
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/bigquery.jobUser"

# Pub/Sub access
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/pubsub.publisher"

gcloud projects add-iam-policy-binding "${GCP_PROJECT}" \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/pubsub.subscriber"

echo "All required IAM roles granted to ${SERVICE_ACCOUNT_EMAIL}."

# === OPTIONAL: Grant USER access for manual Dataflow launches ===
echo "Granting Dataflow dev roles to user ${USER_EMAIL}"

gcloud projects add-iam-policy-binding "${GCP_PROJECT}" \
  --member="user:${USER_EMAIL}" \
  --role="roles/dataflow.developer"
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" \
  --member="user:${USER_EMAIL}" \
  --role="roles/storage.admin"

# === OPTIONAL: Create default VPC and firewall rules for Dataflow jobs ===
echo "Ensuring default network and firewall rules exist."

if ! gcloud compute networks describe default --project="${GCP_PROJECT}" &>/dev/null; then
  gcloud compute networks create default --subnet-mode=auto --project="${GCP_PROJECT}"
fi

if ! gcloud compute firewall-rules describe default-allow-internal --project="${GCP_PROJECT}" &>/dev/null; then
  gcloud compute firewall-rules create default-allow-internal \
    --network=default \
    --allow=tcp,udp,icmp \
    --source-ranges=10.128.0.0/9 \
    --priority=65534 \
    --direction=INGRESS \
    --target-tags=dataflow
fi

if ! gcloud compute firewall-rules describe default-allow-ssh-icmp --project="${GCP_PROJECT}" &>/dev/null; then
  gcloud compute firewall-rules create default-allow-ssh-icmp \
    --network=default \
    --allow=tcp:22,icmp \
    --source-ranges=0.0.0.0/0 \
    --priority=65534 \
    --direction=INGRESS \
    --target-tags=dataflow
fi

echo "Setup complete."
