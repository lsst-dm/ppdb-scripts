#!/usr/bin/env bash

set -euo pipefail

: "${GCP_REGION:?GCP_REGION must be set}"

echo "Active Dataflow jobs in ${GCP_REGION}:"

mapfile -t active_jobs < <(
  gcloud dataflow jobs list \
    --region="${GCP_REGION}" \
    --status=active \
    --format="table(id, name, currentState, currentStateTime)"
)

if (( ${#active_jobs[@]} == 0 )); then
  echo "No active Dataflow jobs found."
  exit 0
fi

printf '%s\n' "${active_jobs[@]}"