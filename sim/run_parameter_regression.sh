#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

for element_count in 4 8 16; do
    echo "[parameter regression] NUM_ELEMENTS=${element_count}"
    NUM_ELEMENTS="$element_count" ./run.sh regress
done

echo "[done] reports are under coverage_report/num_4, num_8 and num_16"
