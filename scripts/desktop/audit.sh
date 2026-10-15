#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091  # Resolved relative to this script at runtime.
source "$SCRIPT_DIR/lib.sh"

desktop_require_safe_home

print_heading() {
  printf '\n[%s]\n' "$1"
}

print_command_state() {
  local command_name=$1

  if command -v "$command_name" >/dev/null 2>&1; then
    printf '%-18s installed\n' "$command_name"
  else
    printf '%-18s missing\n' "$command_name"
  fi
}

print_path_state() {
  local relative_path=$1
  local absolute_path="$HOME/$relative_path"
  local display_path
  display_path=$(desktop_display_path "$absolute_path")

  if [[ -L $absolute_path ]]; then
    local target
    local display_home='~'
    target=$(readlink -- "$absolute_path")
    if [[ $target == "$HOME/"* ]]; then
      target="$display_home/${target#"$HOME/"}"
    fi
    printf '%-52s symlink -> %s\n' "$display_path" "$target"
  elif [[ -d $absolute_path ]]; then
    printf '%-52s directory\n' "$display_path"
  elif [[ -f $absolute_path ]]; then
    printf '%-52s file\n' "$display_path"
  else
    printf '%-52s missing\n' "$display_path"
  fi
}

print_process_state() {
  local process_name=$1
  local count=0
  local matches=""

  if command -v pgrep >/dev/null 2>&1; then
    matches=$(pgrep -x "$process_name" 2>/dev/null || true)
    if [[ -n $matches ]]; then
      count=$(wc -l <<<"$matches")
    fi
  fi

  if ((count > 0)); then
    printf '%-18s running (%d)\n' "$process_name" "$count"
  else
    printf '%-18s not running\n' "$process_name"
  fi
}

print_user_unit_state() {
  local unit=$1
  local active="unavailable"
  local enabled="unavailable"

  if command -v systemctl >/dev/null 2>&1; then
    active=$(systemctl --user is-active "$unit" 2>/dev/null || true)
    enabled=$(systemctl --user is-enabled "$unit" 2>/dev/null || true)
    [[ -n $active ]] || active="unknown"
    [[ -n $enabled ]] || enabled="unknown"
  fi

  printf '%-28s active=%-10s enabled=%s\n' "$unit" "$active" "$enabled"
}

print_heading "host"
if [[ -r /etc/os-release ]]; then
  # PRETTY_NAME is distro-controlled and contains no host identity.
  PRETTY_NAME=""
  # shellcheck disable=SC1091
  source /etc/os-release
  printf 'os                 %s\n' "${PRETTY_NAME:-unknown}"
else
  printf 'os                 unknown\n'
fi
printf 'session            %s\n' "${XDG_SESSION_TYPE:-unknown}"
printf 'desktop            %s\n' "${XDG_CURRENT_DESKTOP:-unknown}"

print_heading "versions"
if command -v Hyprland >/dev/null 2>&1; then
  Hyprland --version 2>/dev/null | sed -n '1p' || true
else
  printf 'Hyprland           missing\n'
fi
if command -v noctalia >/dev/null 2>&1; then
  noctalia --version 2>/dev/null | sed -n '1p' || true
else
  printf 'noctalia           missing\n'
fi
if command -v caelestia >/dev/null 2>&1; then
  caelestia --version 2>/dev/null | sed -n '1p' || true
else
  printf 'caelestia          missing\n'
fi
if command -v qs >/dev/null 2>&1; then
  qs --version 2>/dev/null | sed -n '1p' || true
else
  printf 'quickshell         missing\n'
fi

print_heading "capabilities"
for command_name in \
  caelestia chezmoi ffmpeg hyprctl jq magick matugen noctalia pgrep \
  python3 qs rofi shellcheck shfmt systemctl task; do
  print_command_state "$command_name"
done
unset command_name

print_heading "shell processes"
# Exact process names only. Never print command lines because they can contain
# model paths, tokens, prompts, or other sensitive arguments.
for process_name in noctalia caelestia-shell qs hyprland Hyprland; do
  print_process_state "$process_name"
done
unset process_name

print_heading "relevant user units"
for unit in noctalia.service caelestia.service dms.service; do
  print_user_unit_state "$unit"
done
unset unit

print_heading "managed path candidates"
for relative_path in "${DESKTOP_MANAGED_PATHS[@]}"; do
  print_path_state "$relative_path"
done
unset relative_path

print_heading "hyprland modules"
if [[ -d $HOME/.config/hypr ]]; then
  find "$HOME/.config/hypr" -maxdepth 2 -type f -name '*.lua' -printf '%P\n' \
    2>/dev/null | LC_ALL=C sort
else
  printf 'none\n'
fi

print_heading "noctalia safe settings"
python3 - "$HOME/.config/noctalia/config.toml" \
  "$HOME/.local/state/noctalia/settings.toml" <<'PY'
import pathlib
import sys
import tomllib


def nested(data, *keys):
    current = data
    for key in keys:
        if not isinstance(current, dict) or key not in current:
            return None
        current = current[key]
    return current


def safe_wallpaper(value):
    if not isinstance(value, str) or not value:
        return None
    if value.startswith("color:"):
        return "solid colour"
    return pathlib.Path(value).name


for label, raw_path in (("authored", sys.argv[1]), ("runtime", sys.argv[2])):
    path = pathlib.Path(raw_path)
    print(f"{label}:")
    if not path.is_file():
        print("  state: missing")
        continue

    try:
        with path.open("rb") as stream:
            data = tomllib.load(stream)
    except (OSError, tomllib.TOMLDecodeError) as error:
        print(f"  state: unreadable ({type(error).__name__})")
        continue

    fields = (
        ("theme.mode", nested(data, "theme", "mode")),
        ("theme.source", nested(data, "theme", "source")),
        ("theme.wallpaper_scheme", nested(data, "theme", "wallpaper_scheme")),
        ("wallpaper", safe_wallpaper(nested(data, "wallpaper", "default", "path"))),
    )
    for name, value in fields:
        if value is not None:
            print(f"  {name}: {value}")

    enabled = nested(data, "plugins", "enabled")
    if isinstance(enabled, list):
        safe_plugins = [item for item in enabled if isinstance(item, str)]
        print(f"  plugins.enabled: {', '.join(safe_plugins) if safe_plugins else 'none'}")
PY

print_heading "monitors"
if command -v hyprctl >/dev/null 2>&1 && monitors_json=$(hyprctl monitors -j 2>/dev/null); then
  python3 -c '
import json, sys
for monitor in json.load(sys.stdin):
    # Deliberately omit make, model, description, serial, and workspace names.
    name = monitor.get("name", "unknown")
    width = monitor.get("width", "?")
    height = monitor.get("height", "?")
    refresh = monitor.get("refreshRate", "?")
    scale = monitor.get("scale", "?")
    x = monitor.get("x", "?")
    y = monitor.get("y", "?")
    focused = monitor.get("focused", False)
    print(f"{name}: {width}x{height}@{refresh} scale={scale} position={x},{y} focused={focused}")
' <<<"$monitors_json"
else
  printf 'unavailable outside the active graphical session\n'
fi
unset monitors_json

printf '\nAudit complete. No configuration or process state was changed.\n'
