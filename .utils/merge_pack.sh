#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s inherit_errexit

script_dir=$(dirname -- "$(realpath -m -- "$0")")
declare -r script_dir

function main() {
  if [[ $# -ne 2 ]]; then
    printf 'Usage: %s ORIG_PACK_ZIP AZ_PACK_DIR\n' "$0" >&2
    return 1
  fi
  local src_file="$1"
  local az_dir="$2"

  # Create a temporary directory to work in
  declare -g tmp_dir
  tmp_dir="$(mktemp -d)"
  function cleanup_tmp_dir() { rm -rf -- "$tmp_dir"; }
  trap cleanup_tmp_dir INT TERM EXIT

  # Unzip the original pack
  unzip -q -d "$tmp_dir" -- "$src_file"

  # Copy the AZ textures, update metadata
  rsync -a --exclude='_local' -- "${az_dir}/assets/" "${tmp_dir}/assets/"
  convert -scale 256x256! "${tmp_dir}/pack.png" "${script_dir}/overlay_full.png" -composite "${tmp_dir}/pack.png"
  optipng -o9 -- "${tmp_dir}/pack.png"
  jq '.pack.description = "AZ + \(.pack.description)"' "${tmp_dir}/pack.mcmeta" | sponge "${tmp_dir}/pack.mcmeta"

  # Zip the new pack
  local dst_file
  dst_file="$(dirname -- "$src_file")/AZ + $(basename -- "$src_file")"
  dst_file=$(realpath -m -- "$dst_file")
  rm -f -- "$dst_file"
  pushd "$tmp_dir" >/dev/null
  zip -q -r "$dst_file" .
  popd >/dev/null

  printf 'Created %s\n' "$dst_file"
}

eval 'main "$@";exit "$?"'
