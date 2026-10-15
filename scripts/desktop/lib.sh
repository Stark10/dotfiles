#!/usr/bin/env bash

# Shared constants and guards for desktop management scripts.
# This file is sourced; callers are responsible for enabling strict mode.

DESKTOP_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/stark10-desktop"
# shellcheck disable=SC2034  # Consumed by scripts that source this library.
DESKTOP_SNAPSHOT_DIR="$DESKTOP_STATE_DIR/snapshots"

# Paths are relative to HOME so snapshots can be inspected and restored without
# embedding the account name. Keep this list narrow: rollback trusts only these
# targets, even if a snapshot manifest is modified.
DESKTOP_MANAGED_PATHS=(
  ".config/hypr"
  ".config/noctalia"
  ".local/state/noctalia/settings.toml"
  ".local/share/noctalia/plugins/llama-control"
  ".local/share/noctalia/plugins/quiet-core"
  ".config/alacritty/themes/noctalia.toml"
  ".config/btop/themes/noctalia.theme"
  ".config/gtk-3.0/noctalia.css"
  ".config/gtk-4.0/noctalia.css"
)

desktop_require_safe_home() {
  if [[ -z ${HOME:-} || $HOME != /* || $HOME == "/" ]]; then
    echo "Refusing to continue: HOME must be an absolute, non-root path." >&2
    return 1
  fi

  if [[ ! -d $HOME ]]; then
    echo "Refusing to continue: HOME does not exist: $HOME" >&2
    return 1
  fi
}

desktop_path_is_managed() {
  local candidate=$1
  local managed_path

  for managed_path in "${DESKTOP_MANAGED_PATHS[@]}"; do
    if [[ $candidate == "$managed_path" ]]; then
      return 0
    fi
  done

  return 1
}

desktop_display_path() {
  local path=$1
  local display_home='~'

  if [[ $path == "$HOME" ]]; then
    printf '%s\n' "$display_home"
  elif [[ $path == "$HOME/"* ]]; then
    printf '%s/%s\n' "$display_home" "${path#"$HOME/"}"
  else
    printf '%s\n' "$path"
  fi
}
