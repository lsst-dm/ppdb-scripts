#!/usr/bin/env bash

# Execute this using: source ./setup.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$SCRIPT_DIR:$PATH"

echo "Script directory added to PATH: $SCRIPT_DIR"
