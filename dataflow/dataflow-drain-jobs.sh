#!/usr/bin/env bash
set -euo pipefail

: "${GCP_REGION:?GCP_REGION must be set}"

poll_seconds="${POLL_SECONDS:-20}"
max_wait_seconds="${MAX_WAIT_SECONDS:-0}"

start_time="$(date +%s)"

while true; do
  mapfile -t active_jobs < <(
    gcloud dataflow jobs list \
      --region="${GCP_REGION}" \
      --status=active \
      --format="value(id)"
  )

  if (( ${#active_jobs[@]} == 0 )); then
    echo "No active Dataflow jobs remain."
    exit 0
  fi

  echo "Cancelling ${#active_jobs[@]} active Dataflow job(s) in ${GCP_REGION}..."
  printf '%s\n' "${active_jobs[@]}" | xargs -r -n1 gcloud dataflow jobs cancel \
    --region="${GCP_REGION}" \
    --quiet \
    --force

  if (( max_wait_seconds > 0 )); then
    now="$(date +%s)"
    elapsed=$(( now - start_time ))
    if (( elapsed >= max_wait_seconds )); then
      echo "Timed out after ${elapsed}s waiting for Dataflow jobs to drain." >&2
      exit 1
    fi
  fi

  sleep "${poll_seconds}"
done