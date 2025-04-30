#!/usr/bin/env bash
set -euxo pipefail

if [ -z "${GOOGLE_APPLICATION_CREDENTIALS+x}" ]; then
  echo "GOOGLE_APPLICATION_CREDENTIALS is not set. Please set it to your service account key file."
  exit 1
fi

if [ -z "${GCP_PROJECT+x}" ]; then
  echo "GCP_PROJECT is not set. Please set it to your Google Cloud project ID."
  exit 1
fi

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
