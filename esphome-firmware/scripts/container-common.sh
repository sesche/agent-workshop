#!/usr/bin/env bash

set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
podman_bin="${PODMAN_BIN:-podman}"
container_image="${ESPHOME_CONTAINER_IMAGE:-localhost/esphome-firmware:latest}"
container_workspace="/workspace"
host_cache_root="${ESPHOME_CONTAINER_CACHE_DIR:-$project_root/.podman-cache}"
container_cache_root="$container_workspace/.podman-cache"

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
    "$host_cache_root/platformio"
}

run_esphome_in_container() {
  ensure_container_image
  prepare_container_cache

  "$podman_bin" run --rm \
    --userns keep-id \
    --user "$(id -u):$(id -g)" \
    --volume "$project_root:$container_workspace" \
    --volume "$host_cache_root:$container_cache_root" \
    --workdir "$container_workspace" \
    --env "HOME=$container_cache_root/home" \
    --env "XDG_CACHE_HOME=$container_cache_root/cache" \
    --env "PLATFORMIO_CORE_DIR=$container_cache_root/platformio" \
    "$container_image" \
    "$@"
}
