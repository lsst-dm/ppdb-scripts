#!/usr/bin/env bash

###############################################################################
# Setup the Pub/Sub topics and subscriptions for chunk processing.
###############################################################################

set -euxo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <topic-name>"
  exit 1
fi

TOPIC_NAME=${1}-topic
SUBSCRIPTION_NAME=${1}-sub
DEAD_LETTER_TOPIC_NAME=${1}-dlt

echo "Creating Pub/Sub topic and subscription for $1..."

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
