#!/usr/bin/env bash

# FIXME: Need to add subdirs after scripts were moved around.
# This can probably just be in the root level of the repo.

# Execute this using: source ./setup.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for subdir in bq replication util; do
  echo "Adding $subdir to path..."
  export PATH="$SCRIPT_DIR/$subdir:$PATH"
done

echo "Done setting up path"
