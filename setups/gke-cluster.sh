#!/usr/bin/env bash

###############################################################################
# Setup the GKE cluster for CloudNativePG.
#
# This is just here for reference and probably should not be executed directly.
# The Kubernetes manifests are located in the `k8/cnpg` directory.
# This script is NOT idempotent and should be run only once, or the steps
# should be manually executed and verified.
###############################################################################

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

# Ensure kubectl is installed and working
if ! command -v kubectl >/dev/null 2>&1; then
  echo "Error: kubectl is not installed or not in PATH." >&2
  exit 1
fi

if ! kubectl version --client=true >/dev/null 2>&1; then
  echo "Error: kubectl is not functioning correctly." >&2
  exit 1
fi

check_env_dir "PPDB_SCRIPTS_DIR"

check_var "GCP_PROJECT"
check_var "GCP_REGION"
check_var "GKE_CLUSTER_NAME"
check_var "GKE_WORKLOAD_POOL"

# Enable necessary API
gcloud services enable container.googleapis.com

# Create the GKE cluster
gcloud container clusters create "${GKE_CLUSTER_NAME}" \
  --project="${GCP_PROJECT}" \
  --region="${GCP_REGION}" \
  --release-channel=regular \
  --enable-ip-alias \
  --workload-pool="${GKE_WORKLOAD_POOL}" \
  --num-nodes=3 \
  --machine-type=e2-standard-4

# Get kubeconfig credentials
gcloud container clusters get-credentials "${GKE_CLUSTER_NAME}" \
  --region="${GCP_REGION}" \
  --project="${GCP_PROJECT}"

# Create the namespace for CloudNativePG
kubectl create namespace ppdb

# Apply the CloudNativePG operator manifest
kubectl apply -f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.22/releases/cnpg-1.22.1.yaml

# Create a secret for the PostgreSQL database credentials
DB_PASSWORD="$(openssl rand -base64 32)"
kubectl create secret generic ppdb-pg-credentials \
  --namespace=ppdb \
  --from-literal=username=ppdb_pg_user \
  --from-literal=password="${DB_PASSWORD}"

# Apply the PostgreSQL cluster manifest
kubectl apply -f $PPDB_SCRIPTS_DIR/k8/cnpg/cluster.yaml

# Wait for the CNPG Cluster resource to report "Ready" (untested)
kubectl wait --namespace=ppdb --for=condition=Ready --timeout=300s cluster/ppdb

# Optionally also wait for all pods to be "Ready" (untested)
kubectl wait --namespace=ppdb --for=condition=Ready pod --selector=cnpg.io/cluster=ppdb --timeout=300s

# Apply the LoadBalancer service manifest
kubectl apply -f $PPDB_SCRIPTS_DIR/k8/cnpg/lb.yaml

# FIXME: Wait for the LoadBalancer service to be ready

# Create firewall rule for SLAC
PROJECT_NUMBER=$(gcloud projects describe "$GCP_PROJECT" --format="value(projectNumber)")
SERVICE_ACCOUNT_EMAIL=${PROJECT_NUMBER}-compute@developer.gserviceaccount.com
gcloud compute firewall-rules create allow-ppdb-postgres-from-slac \
  --network=default \
  --direction=INGRESS \
  --priority=1000 \
  --action=ALLOW \
  --rules=tcp:5432 \
  --source-ranges=134.79.23.0/24 \
  --target-service-accounts=${SERVICE_ACCOUNT_EMAIL} \
  --description="Allow PostgreSQL access from SLAC to GKE cluster"

# Get the external IP for the LoadBalancer service
EXTERNAL_IP=$(kubectl get svc ppdb-lb -n ppdb -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Get the password for the PostgreSQL user
PG_PASSWORD=$(kubectl get secret ppdb-pg-credentials -n ppdb -o jsonpath='{.data.password}' | base64 -d)

# Create a secret in Secret Manager for the database password
echo -n "$PG_PASSWORD" | gcloud secrets create ppdb-db-password \
  --project="$GCP_PROJECT" \
  --replication-policy="automatic" \
  --data-file=-

# Add a new version to the secret
echo -n "$PG_PASSWORD" | gcloud secrets versions add ppdb-db-password \
  --project="$GCP_PROJECT" \
  --data-file=-

echo "Created secret..."
gcloud secrets versions list ppdb-db-password \
  --project="$GCP_PROJECT"

# Execute a test query to verify the connection
# FIXME: Database name should eventually be "ppdb" but currently set to "appdb" in the manifest.
PGPASSWORD="$PG_PASSWORD" psql -h "$EXTERNAL_IP" -U ppdb_pg_user -d appdb -c "SELECT 1;"
