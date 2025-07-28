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


check_var "GOOGLE_APPLICATION_CREDENTIALS"
check_var "GCP_PROJECT"

for name in "stage-chunk"; do  # Add more names as needed

  TOPIC_NAME=${name}-topic
  SUBSCRIPTION_NAME=${name}-sub
  DEAD_LETTER_TOPIC_NAME=${name}-dlt

  # Create pubsub topic and subscription
  gcloud pubsub topics create "$TOPIC_NAME" --project="$GCP_PROJECT" || echo "Topic $TOPIC_NAME already exists."

  # Create a dead letter topic
  gcloud pubsub topics create "$DEAD_LETTER_TOPIC_NAME" --project="$GCP_PROJECT" || echo "Dead letter topic $DEAD_LETTER_TOPIC_NAME already exists."

  # Create a subscription to the main topic with a dead letter policy
  gcloud pubsub subscriptions create "$SUBSCRIPTION_NAME" \
    --topic="$TOPIC_NAME" \
    --ack-deadline=300 \
    --dead-letter-topic="$DEAD_LETTER_TOPIC_NAME" \
    --max-delivery-attempts=5 \
    --project="$GCP_PROJECT" || echo "Subscription $SUBSCRIPTION_NAME already exists."

  echo "Created topic $TOPIC_NAME and subscription $SUBSCRIPTION_NAME with dead letter topic $DEAD_LETTER_TOPIC_NAME."

done
