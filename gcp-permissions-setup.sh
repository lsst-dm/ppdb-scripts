#!/usr/bin/env bash

set -euxo pipefail

# === CONFIGURATION ===
if [ -z "${GCP_PROJECT:-}" ]; then
  echo "GCP_PROJECT is unset or empty. Please set it to your environment."
  exit 1
fi

# Set email of currently authenticated user (optional IAM binding later)
USER_EMAIL="${USER_EMAIL:-$(gcloud config get-value account --quiet)}"

# === SET PROJECT CONTEXT ===
gcloud config set project "${GCP_PROJECT}" --quiet
GCP_PROJECT_NUMBER="$(gcloud projects describe "${GCP_PROJECT}" --format='value(projectNumber)' --quiet)"

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
SERVICE_ACCOUNT_KEY_FILE="$HOME/.gcp/keys/${GCP_PROJECT}/${SERVICE_ACCOUNT_NAME}.json"
mkdir -p "$(dirname "${SERVICE_ACCOUNT_KEY_FILE}")"

if [[ ! -f "${SERVICE_ACCOUNT_KEY_FILE}" ]]; then
  echo "Creating service account key: ${SERVICE_ACCOUNT_KEY_FILE}"
  gcloud iam service-accounts keys create "${SERVICE_ACCOUNT_KEY_FILE}" \
    --iam-account="${SERVICE_ACCOUNT_EMAIL}" \
    --quiet
else
  echo "Service account key file already exists: ${SERVICE_ACCOUNT_KEY_FILE}"
fi

# === IAM BINDINGS FOR GCS EVENTING ===
# We have to go through some monkey business to set up GCS eventing with Pub/Sub
# in order to create the service account for it.
# FIXME: Find a better way to do this without creating a temporary bucket and topic.

echo "Granting Pub/Sub Publisher to GCS service account service-${GCP_PROJECT_NUMBER}@gs-project-accounts.iam.gserviceaccount.com"

TEMP_TOPIC="gcs-trigger-topic-${GCP_PROJECT}"
TEMP_BUCKET="gcs-trigger-${GCP_PROJECT}-$(uuidgen | tr '[:upper:]' '[:lower:]' | cut -d- -f1)"

# Create topic
gcloud pubsub topics create "${TEMP_TOPIC}" --project="${GCP_PROJECT}" --quiet || true

# Create bucket
gsutil mb -p "${GCP_PROJECT}" "gs://${TEMP_BUCKET}"

# Try notification once (it may fail)
if ! gsutil notification create -t "${TEMP_TOPIC}" -f json "gs://${TEMP_BUCKET}"; then
  echo "First notification creation failed — waiting for service account to be provisioned..."
  sleep 15
  # Try again
  gsutil notification create -t "${TEMP_TOPIC}" -f json "gs://${TEMP_BUCKET}"
fi

# Now grant Pub/Sub role
GCS_SVC_EMAIL="service-${GCP_PROJECT_NUMBER}@gs-project-accounts.iam.gserviceaccount.com"
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" \
  --member="serviceAccount:${GCS_SVC_EMAIL}" \
  --role="roles/pubsub.publisher" \
  --quiet

# Optional cleanup
gsutil notification delete "gs://${TEMP_BUCKET}"
gsutil rm -r "gs://${TEMP_BUCKET}"
gcloud pubsub topics delete "${TEMP_TOPIC}" --quiet

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

# Pub/Sub
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" --quiet \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/pubsub.subscriber"

# Storage admin
gcloud projects add-iam-policy-binding "${GCP_PROJECT}" --quiet \
  --member="user:${USER_EMAIL}" \
  --role="roles/storage.admin"

echo "All required IAM roles granted to ${SERVICE_ACCOUNT_EMAIL}."

# === OPTIONAL: CREATE DEFAULT NETWORK AND FIREWALL RULES FOR DATAFLOW ===
echo "Ensuring default network and firewall rules exist."

if ! gcloud compute networks describe default --project="${GCP_PROJECT}" &>/dev/null; then
  gcloud compute networks create default --subnet-mode=auto --project="${GCP_PROJECT}" --quiet
fi

# Need to enable Google Compute Engine API before doing this by visiting:
# https://console.developers.google.com/apis/api/compute.googleapis.com/overview?project=${GCP_PROJECT}
if ! gcloud compute firewall-rules describe default-allow-internal --project="${GCP_PROJECT}" &>/dev/null; then
  gcloud compute firewall-rules create default-allow-internal \
    --network=default \
    --allow=tcp,udp,icmp \
    --source-ranges=10.128.0.0/9 \
    --priority=65534 \
    --direction=INGRESS \
    --target-tags=dataflow \
    --project="${GCP_PROJECT}" \
    --quiet
fi

if ! gcloud compute firewall-rules describe default-allow-ssh-icmp --project="${GCP_PROJECT}" &>/dev/null; then
  gcloud compute firewall-rules create default-allow-ssh-icmp \
    --network=default \
    --allow=tcp:22,icmp \
    --source-ranges=0.0.0.0/0 \
    --priority=65534 \
    --direction=INGRESS \
    --target-tags=dataflow \
    --project="${GCP_PROJECT}" \
    --quiet
fi

echo "Setup complete."
