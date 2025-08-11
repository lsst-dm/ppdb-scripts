#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]] || ! [[ "$1" =~ ^[0-9]+$ ]]; then
    echo "Usage: $0 <number_of_times>"
    exit 1
fi

count="$1"

for ((i = 1; i <= count; i++)); do
    echo "Export run $i of $count"
    export-chunks.sh --single
done

upload-chunks.sh