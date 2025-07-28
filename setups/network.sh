#!/usr/bin/env bash

###############################################################################
# This script creates the virtual network and firewall rules needed for the
# PPDB Dataflow jobs which are run in worker VMs from the Docker containers.
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
  return 1
fi

# Check for gcloud command
if ! command -v gcloud >/dev/null 2>&1; then
  echo "gcloud command not found. Please install the Google Cloud SDK."
  exit 1
fi

# Set the project ID from the environment
GCP_PROJECT=$(gcloud config get-value project)

# Prompt for confirmation before making changes
read -r -p "This script will modify GCP networking resources in project ${GCP_PROJECT}. Continue? [y/N] " confirm
confirm=$(echo "$confirm" | xargs)  # Trim leading/trailing whitespace
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 1
fi

# Enable the required Compute service before proceeding
echo "Enabling Compute service for GCP project: ${GCP_PROJECT}"
gcloud services enable compute.googleapis.com --project="${GCP_PROJECT}" --quiet
echo "Compute service enabled."

# Create default network if it doesn't exist
if ! gcloud compute networks describe default --project="${GCP_PROJECT}" &>/dev/null; then
  gcloud compute networks create default --subnet-mode=auto --project="${GCP_PROJECT}" --quiet
else
  echo "Default network already exists."
fi

# Create the default internal firewall rule if it doesn't exist
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
else
  echo "Firewall rule default-allow-internal already exists."
fi

# Create the default SSH and ICMP firewall rule if it doesn't exist
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
else
  echo "Firewall rule default-allow-ssh-icmp already exists."
fi

echo "Network creation complete."
