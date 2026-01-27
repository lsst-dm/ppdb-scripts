#!/usr/bin/env bash

###############################################################################
# Enable the necessary Google Cloud services for PPDB.
###############################################################################

# FIXME: Some of the services may be redundantly enabled by other scripts.

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
  secretmanager.googleapis.com \
  serviceusage.googleapis.com \
  sqladmin.googleapis.com \
  storage.googleapis.com