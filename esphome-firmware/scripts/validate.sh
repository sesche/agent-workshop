#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <device-yaml>"
  exit 1
fi

if ! command -v esphome >/dev/null 2>&1; then
  echo "ESPHome CLI is not installed or not on PATH."
  exit 127
fi

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$project_root"
esphome config "$1"
