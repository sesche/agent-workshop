#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=container-common.sh
source "$script_dir/container-common.sh"

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  echo "Usage: $0 <device-yaml> [serial-port]"
  echo
  echo "Set ESPHOME_SERIAL_PORT to avoid passing the port each time."
  exit 1
fi

device_file="$1"
serial_port="${2:-${ESPHOME_SERIAL_PORT:-}}"

if [ ! -f "$project_root/$device_file" ] && [ ! -f "$device_file" ]; then
  echo "Device YAML not found: $device_file"
  exit 1
fi

if [ -z "$serial_port" ]; then
  echo "A USB serial port is required."
  echo "Pass it as the second argument or set ESPHOME_SERIAL_PORT."
  exit 1
fi

if [ ! -e "$serial_port" ]; then
  echo "Serial device not found: $serial_port"
  exit 1
fi

echo "Compiling $device_file"
run_esphome_in_container compile "$device_file"

echo "Uploading $device_file to $serial_port"
run_esphome_in_container \
  --podman-arg "--device=$serial_port:$serial_port" \
  upload "$device_file" --device "$serial_port"
