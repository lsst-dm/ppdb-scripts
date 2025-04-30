#!/usr/bin/env bash

set -euxo pipefail

gcloud storage ls --recursive gs://rubin-ppdb-test-bucket-1/$1
