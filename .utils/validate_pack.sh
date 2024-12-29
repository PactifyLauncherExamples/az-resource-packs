#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s inherit_errexit

declare -r STDOUT_SUCCESS=$'\e[32m'
declare -r STDOUT_ERROR=$'\e[31m'
declare -r STDOUT_RESET=$'\e[0m'

function main() {
  if [[ $# -ne 1 ]]; then
    printf 'Usage: %s DIRECTORY\n' "$0" >&2
    return 1
  fi
  local pack_dir="$1"
  local errors_count=0

  # Check and validate known files
  declare -A known_files_set
  local known_file result
  for known_file in $(known_files); do
    known_files_set["$known_file"]=1
    result=$(check_file "$pack_dir" "$known_file")
    case "$result" in
    O*)
      printf '%s[✓]%s %s\n' "$STDOUT_SUCCESS" "$STDOUT_RESET" "$known_file"
      ;;
    E*)
      errors_count=$((errors_count + 1))
      printf '%s[✗]%s %s\n' "$STDOUT_ERROR" "$STDOUT_RESET" "$known_file"
      printf ' └─ %s\n' "${result:2}"
      ;;
    *)
      printf 'Unexpected result: %s\n' "$result" >&2
      return 1
      ;;
    esac
  done

  # Ensure no extra files are present
  local file
  while IFS= read -r -d '' file; do
    if [[ -v known_files_set["$file"] ]]; then
      continue
    fi

    errors_count=$((errors_count + 1))
    printf '%s[✗]%s %s\n' "$STDOUT_ERROR" "$STDOUT_RESET" "$file"
    printf ' └─ Unknown file\n'
  done < <(find "$pack_dir" \( -type d -name _local -prune \) -o -type f -printf '%P\0')

  # Print summary and exit
  if [[ $errors_count -ne 0 ]]; then
    printf '%s▶ %d errors%s\n' "$STDOUT_ERROR" "$errors_count" "$STDOUT_RESET"
    return 1
  else
    printf "%s▶ It's all good!%s\n" "$STDOUT_SUCCESS" "$STDOUT_RESET"
  fi
}

function check_file() {
  local pack_dir="$1"
  local filename="$2"

  # Check if the file exists
  local file="${pack_dir}/${filename}"
  if [[ ! -f "$file" ]]; then
    printf 'E Missing file'
    return
  fi

  # Validate the file
  case "$filename" in
  pack.mcmeta)
    local pack_format
    pack_format=$(jq -r .pack.pack_format -- "$file" 2>/dev/null || true)
    if [[ "$pack_format" != 2 ]]; then
      printf 'E Invalid pack_format: %s' "$pack_format"
      return
    fi
    ;;
  *.png)
    local png_identity
    png_identity=$(identify -format '%m | %z | %[colorspace]' -- "$file" 2>&1)
    if [[ ! "$png_identity" =~ ^'PNG | 8 | '(sRGB|Gray)$ ]]; then
      printf 'E Invalid PNG: %s' "$png_identity"
      return
    fi
    ;;
  *.png.mcmeta)
    if ! jq -e . -- "$file" >/dev/null 2>&1; then
      printf 'E Invalid JSON'
      return
    fi
    ;;
  esac

  # Everything is OK
  printf 'O'
}

function known_files() {
  cat <<'EOF'
pack.mcmeta
pack.png
assets/azlauncher/textures/blocks/colored_portal.png
assets/azlauncher/textures/blocks/colored_portal.png.mcmeta
assets/azlauncher/textures/generic_items/metal_axe.png
assets/azlauncher/textures/generic_items/metal_axe_handle.png
assets/azlauncher/textures/generic_items/metal_axe_handle.png.mcmeta
assets/azlauncher/textures/generic_items/metal_axe_outline.png
assets/azlauncher/textures/generic_items/metal_boots.png
assets/azlauncher/textures/generic_items/metal_boots_glow.png
assets/azlauncher/textures/generic_items/metal_boots_outline.png
assets/azlauncher/textures/generic_items/metal_boots_outline.png.mcmeta
assets/azlauncher/textures/generic_items/metal_chestplate.png
assets/azlauncher/textures/generic_items/metal_chestplate_glow.png
assets/azlauncher/textures/generic_items/metal_chestplate_outline.png
assets/azlauncher/textures/generic_items/metal_chestplate_outline.png.mcmeta
assets/azlauncher/textures/generic_items/metal_helmet.png
assets/azlauncher/textures/generic_items/metal_helmet_glow.png
assets/azlauncher/textures/generic_items/metal_helmet_inside.png
assets/azlauncher/textures/generic_items/metal_helmet_inside.png.mcmeta
assets/azlauncher/textures/generic_items/metal_helmet_outline.png
assets/azlauncher/textures/generic_items/metal_helmet_outline.png.mcmeta
assets/azlauncher/textures/generic_items/metal_hoe.png
assets/azlauncher/textures/generic_items/metal_hoe_handle.png
assets/azlauncher/textures/generic_items/metal_hoe_handle.png.mcmeta
assets/azlauncher/textures/generic_items/metal_hoe_outline.png
assets/azlauncher/textures/generic_items/metal_leggings.png
assets/azlauncher/textures/generic_items/metal_leggings_glow.png
assets/azlauncher/textures/generic_items/metal_leggings_outline.png
assets/azlauncher/textures/generic_items/metal_leggings_outline.png.mcmeta
assets/azlauncher/textures/generic_items/metal_pickaxe.png
assets/azlauncher/textures/generic_items/metal_pickaxe_handle.png
assets/azlauncher/textures/generic_items/metal_pickaxe_handle.png.mcmeta
assets/azlauncher/textures/generic_items/metal_pickaxe_outline.png
assets/azlauncher/textures/generic_items/metal_shovel.png
assets/azlauncher/textures/generic_items/metal_shovel_handle.png
assets/azlauncher/textures/generic_items/metal_shovel_handle.png.mcmeta
assets/azlauncher/textures/generic_items/metal_shovel_outline.png
assets/azlauncher/textures/generic_items/metal_sword.png
assets/azlauncher/textures/generic_items/metal_sword_cross.png
assets/azlauncher/textures/generic_items/metal_sword_cross_outline.png
assets/azlauncher/textures/generic_items/metal_sword_handle.png
assets/azlauncher/textures/generic_items/metal_sword_handle.png.mcmeta
assets/azlauncher/textures/generic_items/metal_sword_outline.png
assets/azlauncher/textures/gui/container/cosmetics.png
assets/azlauncher/textures/gui/container/cosmetics.png.mcmeta
assets/azlauncher/textures/gui/tooltip_frame/epic.png
assets/azlauncher/textures/gui/tooltip_frame/legendary.png
assets/azlauncher/textures/gui/tooltip_frame/mythic.png
assets/azlauncher/textures/gui/tooltip_frame/rare.png
assets/azlauncher/textures/gui/tooltip_frame/uncommon.png
assets/azlauncher/textures/items/emerald_axe.png
assets/azlauncher/textures/items/emerald_boots.png
assets/azlauncher/textures/items/emerald_chestplate.png
assets/azlauncher/textures/items/emerald_helmet.png
assets/azlauncher/textures/items/emerald_hoe.png
assets/azlauncher/textures/items/emerald_leggings.png
assets/azlauncher/textures/items/emerald_pickaxe.png
assets/azlauncher/textures/items/emerald_shovel.png
assets/azlauncher/textures/items/emerald_sword.png
assets/azlauncher/textures/models/armor/emerald_layer_1.png
assets/azlauncher/textures/models/armor/emerald_layer_2.png
assets/azlauncher/textures/models/generic_armor/metal_layer_1.png
assets/azlauncher/textures/models/generic_armor/metal_layer_1_glow.png
assets/azlauncher/textures/models/generic_armor/metal_layer_1_outline.png
assets/azlauncher/textures/models/generic_armor/metal_layer_2.png
assets/azlauncher/textures/models/generic_armor/metal_layer_2_glow.png
assets/azlauncher/textures/models/generic_armor/metal_layer_2_outline.png
EOF
}

eval 'main "$@";exit "$?"'
