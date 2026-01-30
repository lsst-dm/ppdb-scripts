#!/usr/bin/env bash

###############################################################################
# Set up Pub/Sub permissions on the SA.
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

check_var "SERVICE_ACCOUNT_EMAIL"

# Grant the primary SA permission to publish to stage-chunk-topic
gcloud pubsub topics add-iam-policy-binding stage-chunk-topic \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/pubsub.publisher"

# Grant the primary SA permission to publish to track-chunk-topic
gcloud pubsub topics add-iam-policy-binding track-chunk-topic \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/pubsub.publisher"

echo "Pub/Sub setup completed successfully."
