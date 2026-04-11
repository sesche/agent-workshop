#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=container-common.sh
source "$script_dir/container-common.sh"

device_files=("$@")

if [ "${#device_files[@]}" -eq 0 ]; then
  shopt -s nullglob
  device_files=("$project_root"/devices/*.yaml)
  shopt -u nullglob

  if [ "${#device_files[@]}" -eq 0 ]; then
    echo "No device YAML files were found in $project_root/devices."
    exit 1
  fi

  for i in "${!device_files[@]}"; do
    device_files[$i]="${device_files[$i]#$project_root/}"
  done
fi

for device_file in "${device_files[@]}"; do
  echo "Validating $device_file"
  run_esphome_in_container config "$device_file"
done
