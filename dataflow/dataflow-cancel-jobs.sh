#!/usr/bin/env bash

set -euxo pipefail

#gcloud dataflow jobs list \
#    --region="${GCP_REGION}" \
#    --format="value(id,state)" | \
#awk '$2 == "Running" || $2 == "Queued" || $2 == "Starting..." {print $1}' | \
#xargs -r -n1 gcloud dataflow jobs cancel --region="${GCP_REGION}" --force --quiet

gcloud dataflow jobs list \
    --region="${GCP_REGION}" \
    --status=active \
    --format="value(id)" | \
xargs -r -n1 gcloud dataflow jobs cancel --region="${GCP_REGION}"
