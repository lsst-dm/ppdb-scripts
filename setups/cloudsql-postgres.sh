#!/usr/bin/env bash

###############################################################################
# Set up a PostgreSQL Cloud SQL instance for PPDB.
#
# This script creates a Cloud SQL PostgreSQL instance with minimal
# configuration. It should eventually be fine-tuned for production use.
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

check_var "GCP_PROJECT"
check_var "GCP_REGION"
check_var "PPDB_DB_USER"

# Configuration variables - modify as needed
CLOUDSQL_INSTANCE_NAME="ppdb"
CLOUDSQL_DATABASE_NAME="ppdb-chunk-tracking"

# Generate secure passwords
CLOUDSQL_ROOT_PASSWORD=$(openssl rand -base64 32)
CLOUDSQL_APP_PASSWORD=$(openssl rand -base64 32)

CLOUDSQL_TIER=db-perf-optimized-N-2
CLOUDSQL_APP_USER=${PPDB_DB_USER}

# Enable necessary APIs
gcloud services enable sqladmin.googleapis.com

# Create the Cloud SQL PostgreSQL instance
echo "Creating Cloud SQL PostgreSQL instance: ${CLOUDSQL_INSTANCE_NAME}"
if gcloud sql instances describe "${CLOUDSQL_INSTANCE_NAME}" >/dev/null 2>&1; then
  echo "ERROR: Cloud SQL instance ${CLOUDSQL_INSTANCE_NAME} already exists."
  echo "This script is designed to create a new instance. Exiting."
  exit 1
else
  gcloud sql instances create "${CLOUDSQL_INSTANCE_NAME}" \
    --database-version=POSTGRES_16 \
    --region="${GCP_REGION}" \
    --tier=db-perf-optimized-N-2 \
    --assign-ip \
    --authorized-networks=0.0.0.0/0 \
    --root-password="${CLOUDSQL_ROOT_PASSWORD}"
  echo "Cloud SQL instance ${CLOUDSQL_INSTANCE_NAME} created successfully."
fi

# Create the database
echo "Creating database: ${CLOUDSQL_DATABASE_NAME}"
gcloud sql databases create "${CLOUDSQL_DATABASE_NAME}" \
  --instance="${CLOUDSQL_INSTANCE_NAME}"

echo "Database ${CLOUDSQL_DATABASE_NAME} created successfully."

# Create application user
echo "Creating application user: ${CLOUDSQL_APP_USER}"
gcloud sql users create "${CLOUDSQL_APP_USER}" \
  --instance="${CLOUDSQL_INSTANCE_NAME}" \
  --password="${CLOUDSQL_APP_PASSWORD}"

echo "Application user ${CLOUDSQL_APP_USER} created successfully."

# Get the public IP (if available)
PUBLIC_IP=$(gcloud sql instances describe "${CLOUDSQL_INSTANCE_NAME}" --format="value(ipAddresses[0].ipAddress)" 2>/dev/null || echo "Not available")
echo "Public IP: ${PUBLIC_IP}"

# Create a secret in Secret Manager for the database password
echo -n "$CLOUDSQL_APP_PASSWORD" | gcloud secrets create ppdb-db-password \
  --project="$GCP_PROJECT" \
  --replication-policy="automatic" \
  --data-file=-

# Add a new version to the secret
#echo -n "$CLOUDSQL_APP_PASSWORD" | gcloud secrets versions add ppdb-db-password \
#  --project="$GCP_PROJECT" \
#  --data-file=-

echo "Created secret..."
gcloud secrets versions list ppdb-db-password \
  --project="$GCP_PROJECT"

echo ""
echo "=== Connection Strings ==="
echo "Use these full PostgreSQL connection strings:"
echo ""
echo "App user:"
echo "postgresql://${CLOUDSQL_APP_USER}:${CLOUDSQL_APP_PASSWORD}@${PUBLIC_IP}:5432/${CLOUDSQL_DATABASE_NAME}"
echo ""
echo "Root user:"
echo "postgresql://postgres:${CLOUDSQL_ROOT_PASSWORD}@${PUBLIC_IP}:5432/${CLOUDSQL_DATABASE_NAME}"
echo ""
echo "=== .pgpass file entries ==="
echo "Add these lines to your ~/.pgpass file for password-free connections:"
echo ""
echo "${PUBLIC_IP}:5432:${CLOUDSQL_DATABASE_NAME}:postgres:${CLOUDSQL_ROOT_PASSWORD}"
echo "${PUBLIC_IP}:5432:${CLOUDSQL_DATABASE_NAME}:${CLOUDSQL_APP_USER}:${CLOUDSQL_APP_PASSWORD}"

echo ""
