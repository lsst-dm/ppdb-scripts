#!/usr/bin/env bash

set -euxo pipefail

# Prevent sourcing
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  echo "Error: this script must be executed, not sourced." >&2
  return 1
fi

# Require check_var function
if ! declare -F check_var >/dev/null; then
  echo "check_var is not defined." >&2
  exit 1
fi

check_var "GCP_PROJECT"
check_var "GCP_REGION"
check_var "SERVICE_ACCOUNT_EMAIL"

PROJECT_NUMBER=$(gcloud projects describe "$GCP_PROJECT" --format="value(projectNumber)")

gcloud services enable vpcaccess.googleapis.com

gcloud compute networks vpc-access connectors create ppdb-vpc-connector \
  --region=${GCP_REGION} \
  --network=default \
  --range=10.8.0.0/28

GKE_TAG=$(gcloud compute instances list \
  --filter="name~'^gke-${GKE_CLUSTER_NAME}'" \
  --limit=1 \
  --format="value(tags.items[0])")

echo "Detected GKE node tag: ${GKE_TAG}"

gcloud compute firewall-rules create allow-ppdb-postgres-from-vpc-connector \
  --network=default \
  --direction=INGRESS \
  --priority=1000 \
  --action=ALLOW \
  --rules=tcp:5432 \
  --source-ranges=10.8.0.0/28 \
  --target-tags="${GKE_TAG}" \
  --description="Allow PostgreSQL access from Serverless VPC connector to GKE nodes"
