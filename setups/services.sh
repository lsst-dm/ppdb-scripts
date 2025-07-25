#!/usr/bin/env bash

set -euxo pipefail

gcloud services enable \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com \
  cloudfunctions.googleapis.com \
  cloudresourcemanager.googleapis.com \
  compute.googleapis.com \
  dataflow.googleapis.com \
  iam.googleapis.com \
  logging.googleapis.com \
  pubsub.googleapis.com \
  run.googleapis.com \
  serviceusage.googleapis.com \
  storage.googleapis.com
