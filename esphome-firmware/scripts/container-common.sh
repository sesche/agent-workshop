#!/usr/bin/env bash

set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
podman_bin="${PODMAN_BIN:-podman}"
container_image="${ESPHOME_CONTAINER_IMAGE:-localhost/esphome-firmware:latest}"
container_config_root="/config"
host_cache_root="${ESPHOME_CONTAINER_CACHE_DIR:-$project_root/.podman-cache}"
container_cache_root="$container_config_root/.podman-cache"
host_secrets_file="$project_root/secrets.yaml"

require_podman() {
  if ! command -v "$podman_bin" >/dev/null 2>&1; then
    echo "Podman is not installed or not on PATH."
    exit 127
  fi
}

build_container_image() {
  require_podman

  "$podman_bin" build \
    --tag "$container_image" \
    --file "$project_root/Containerfile" \
    "$project_root"
}

ensure_container_image() {
  require_podman

  if ! "$podman_bin" image exists "$container_image"; then
    echo "Podman image $container_image is missing, building it now..."
    build_container_image
  fi
}

prepare_container_cache() {
  mkdir -p \
    "$host_cache_root/home" \
    "$host_cache_root/cache" \
    "$host_cache_root/platformio" \
    "$host_cache_root/esphome"
}

run_esphome_in_container() {
  local podman_args=()

  ensure_container_image
  prepare_container_cache

  podman_args=(
    run
    --rm
    --userns keep-id \
    --user "$(id -u):$(id -g)" \
    --volume "$project_root:$container_config_root" \
    --volume "$host_cache_root/esphome:$container_config_root/.esphome" \
    --volume "$host_cache_root:$container_cache_root" \
    --workdir "$container_config_root" \
    --env "HOME=$container_cache_root/home" \
    --env "XDG_CACHE_HOME=$container_cache_root/cache" \
    --env "PLATFORMIO_CORE_DIR=$container_cache_root/platformio" \
  )

  if [ -f "$host_secrets_file" ]; then
    # ESPHome resolves !secret lookups relative to the active file and included packages,
    # so mount the repo-level secrets file into the locations it probes for this layout.
    podman_args+=(
      --volume "$host_secrets_file:$container_config_root/devices/secrets.yaml:ro"
      --volume "$host_secrets_file:$container_config_root/packages/common/secrets.yaml:ro"
    )
  fi

  podman_args+=(
    "$container_image"
    "$@"
  )

  "$podman_bin" "${podman_args[@]}"
}
