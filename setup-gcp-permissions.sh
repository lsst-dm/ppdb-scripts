#!/usr/bin/env bash

set -e
set -x

# === CONFIGURATION ===
PROJECT_ID="${PROJECT_ID:-ppdb-dev-438721}"
SERVICE_ACCOUNT="${SERVICE_ACCOUNT:-ppdb-storage-manager@${PROJECT_ID}.iam.gserviceaccount.com}"
BUCKET_NAME="${BUCKET_NAME:-rubin-ppdb-test-bucket-1}"
USER_EMAIL="${USER_EMAIL:-$(gcloud config get-value account)}"

# === PREVENT SCRIPT EXECUTION AS A SERVICE ACCOUNT ===
if [[ "$USER_EMAIL" == *gserviceaccount.com ]]; then
  echo "ERROR: This script must be run as a user account, not a service account."
  echo "Current account: $USER_EMAIL"
  echo "Run 'gcloud auth login' to switch."
  exit 1
fi

# === IAM BINDINGS FOR YOUR SERVICE ACCOUNT ===
echo "Granting Cloud Functions and Dataflow roles to $SERVICE_ACCOUNT"

# Cloud Functions (Gen 1 deployment)
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/cloudfunctions.developer"

# Allow impersonation and execution of services
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/iam.serviceAccountUser"

# Full access to GCS
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/storage.admin"

# Dataflow job submission and execution
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/dataflow.developer"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/dataflow.worker"

# Allow log writing
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/logging.logWriter"

# === GRANT NETWORK ACCESS ===
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/compute.networkUser"

echo "All required IAM roles granted to $SERVICE_ACCOUNT for Cloud Functions and Dataflow."

# === OPTIONAL: Grant user access to launch Dataflow manually ===
echo "Granting Dataflow dev roles to user $USER_EMAIL"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="user:$USER_EMAIL" \
  --role="roles/dataflow.developer"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="user:$USER_EMAIL" \
  --role="roles/storage.admin"

# === OPTIONAL: Create a default network for Dataflow jobs ===
if ! gcloud compute networks describe default --project="$PROJECT_ID" &>/dev/null; then
  gcloud compute networks create default --subnet-mode=auto --project="$PROJECT_ID"
fi

if ! gcloud compute firewall-rules describe default-allow-internal --project="$PROJECT_ID" &>/dev/null; then
  gcloud compute firewall-rules create default-allow-internal \
    --network=default \
    --allow tcp,udp,icmp \
    --source-ranges=10.128.0.0/9 \
    --priority=65534 \
    --direction=INGRESS \
    --target-tags=dataflow
fi

if ! gcloud compute firewall-rules describe default-allow-ssh-icmp --project="$PROJECT_ID" &>/dev/null; then
  gcloud compute firewall-rules create default-allow-ssh-icmp \
    --network=default \
    --allow tcp:22,icmp \
    --source-ranges=0.0.0.0/0 \
    --priority=65534 \
    --direction=INGRESS \
    --target-tags=dataflow
fi

# === BIGQUERY PERMISSIONS ===
echo "Granting BigQuery permissions to $SERVICE_ACCOUNT"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/bigquery.dataEditor"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/bigquery.jobUser"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/bigquery.admin"

echo "Setup complete."
