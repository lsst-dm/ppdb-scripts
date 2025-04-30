#!/usr/bin/env bash

set -euxo pipefail

gcloud auth activate-service-account --key-file="$HOME/.gcp/keys/ppdb-storage-manager-key.json"
