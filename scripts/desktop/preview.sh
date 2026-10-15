#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)
# shellcheck disable=SC1091  # Resolved relative to this script at runtime.
source "$SCRIPT_DIR/lib.sh"

PROPOSED_CONFIG="$REPO_ROOT/desktop/proposed/noctalia/config.toml"
PROTOTYPE_PLUGIN="$REPO_ROOT/desktop/prototypes/noctalia/quiet-core"
LIVE_CONFIG="$HOME/.config/noctalia/config.toml"
LIVE_SETTINGS="$HOME/.local/state/noctalia/settings.toml"
LIVE_PLUGIN="$HOME/.local/share/noctalia/plugins/quiet-core"
PREVIEW_DIR="$DESKTOP_STATE_DIR/previews"
PREVIEW_MARKER="$PREVIEW_DIR/active"

usage() {
  cat <<'EOF'
Usage: preview.sh [--dry-run] [--yes]

Install and open the guarded Quiet Core Noctalia preview. The script validates
first, refuses while Llama is handling an active request, takes a targeted
snapshot, and rolls back automatically if installation or health checks fail.
It does not restart Noctalia, Hyprland, Llama, or any service.
EOF
}

dry_run=false
assume_yes=false

while (($# > 0)); do
  case $1 in
    --dry-run)
      dry_run=true
      ;;
    --yes)
      assume_yes=true
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

desktop_require_safe_home

for required_path in \
  "$PROPOSED_CONFIG" \
  "$PROTOTYPE_PLUGIN/plugin.toml" \
  "$PROTOTYPE_PLUGIN/dashboard.luau" \
  "$PROTOTYPE_PLUGIN/widget.luau"; do
  if [[ ! -f $required_path ]]; then
    echo "Preview input is missing: $required_path" >&2
    exit 1
  fi
done
unset required_path

if ! command -v noctalia >/dev/null 2>&1; then
  echo "Noctalia is required for the live preview." >&2
  exit 1
fi

if [[ -e $PREVIEW_MARKER ]]; then
  echo "A preview is already active according to: $PREVIEW_MARKER" >&2
  echo "Rollback or archive that preview before starting another." >&2
  exit 1
fi

if pgrep -x llama-cli >/dev/null 2>&1; then
  echo "Refusing preview while protected process 'llama-cli' is running." >&2
  exit 1
fi

if pgrep -x llama-server >/dev/null 2>&1; then
  llama_control=$(command -v llama-control || true)
  llama_status=""
  active_requests=""
  if [[ -n $llama_control ]] &&
    llama_status=$("$llama_control" status 2>/dev/null) &&
    active_requests=$(python3 -c '
import json, sys
status = json.load(sys.stdin)
requests = status.get("requests")
if not isinstance(requests, (int, float)):
    raise SystemExit(1)
print(int(requests))
' <<<"$llama_status"); then
    if ((active_requests > 0)); then
      echo "Refusing preview while Llama is handling $active_requests active request(s)." >&2
      exit 1
    fi
    printf 'Llama server is loaded but idle; continuing without touching it.\n'
  else
    echo "Refusing preview: Llama is running and its active-request state could not be verified." >&2
    exit 1
  fi
fi

"$SCRIPT_DIR/validate.sh"

printf '\nQuiet Core preview plan:\n'
printf '  snapshot  %s\n' "$(desktop_display_path "$DESKTOP_SNAPSHOT_DIR")"
printf '  config    %s\n' "$(desktop_display_path "$LIVE_CONFIG")"
printf '  reconcile %s (remove only [bar.default] overrides)\n' "$(desktop_display_path "$LIVE_SETTINGS")"
printf '  plugin    %s\n' "$(desktop_display_path "$LIVE_PLUGIN")"
printf '  palette   wallpaper soft\n'
printf '  open      samh/quiet-core:dashboard\n'
printf '  untouched Hyprland config, services, session, and running processes\n'

if [[ $dry_run == true ]]; then
  printf '\nDry run complete. Nothing was changed.\n'
  exit 0
fi

if ! GSETTINGS_BACKEND=memory noctalia msg status >/dev/null; then
  echo "Noctalia IPC is unavailable in this graphical session." >&2
  exit 1
fi

if [[ $assume_yes == false ]]; then
  if [[ ! -t 0 ]]; then
    echo "Refusing non-interactive preview without --yes." >&2
    exit 1
  fi
  printf 'Start this reversible live preview? [y/N] '
  read -r confirmation
  if [[ ! $confirmation =~ ^[Yy]$ ]]; then
    echo "Preview cancelled."
    exit 0
  fi
fi

snapshot_id=$("$SCRIPT_DIR/snapshot.sh" --quiet | tail -n 1)
snapshot_path="$DESKTOP_SNAPSHOT_DIR/$snapshot_id"
plugin_stage=""
config_stage=""
settings_stage=""

recover_preview() {
  local exit_code=$?
  trap - ERR
  set +e
  printf '\nPreview failed; restoring snapshot %s.\n' "$snapshot_id" >&2
  "$SCRIPT_DIR/rollback.sh" --snapshot "$snapshot_id" --yes >&2
  GSETTINGS_BACKEND=memory noctalia msg config-reload >/dev/null 2>&1
  if [[ -n $plugin_stage && -d $plugin_stage ]]; then
    mkdir -p "$snapshot_path/unused-preview-staging"
    mv -- "$plugin_stage" "$snapshot_path/unused-preview-staging/quiet-core"
  fi
  if [[ -n $config_stage && -f $config_stage ]]; then
    mkdir -p "$snapshot_path/unused-preview-staging"
    mv -- "$config_stage" "$snapshot_path/unused-preview-staging/config.toml"
  fi
  if [[ -n $settings_stage && -f $settings_stage ]]; then
    mkdir -p "$snapshot_path/unused-preview-staging"
    mv -- "$settings_stage" "$snapshot_path/unused-preview-staging/settings.toml"
  fi
  printf 'Automatic rollback finished.\n' >&2
  exit "$exit_code"
}
trap recover_preview ERR

plugin_parent=$(dirname -- "$LIVE_PLUGIN")
mkdir -p -- "$plugin_parent"
plugin_stage=$(mktemp -d "$plugin_parent/.quiet-core.preview.XXXXXX")
cp -a -- "$PROTOTYPE_PLUGIN/." "$plugin_stage/"

if [[ -e $LIVE_PLUGIN || -L $LIVE_PLUGIN ]]; then
  replaced_plugin="$snapshot_path/replaced-by-preview/.local/share/noctalia/plugins/quiet-core"
  mkdir -p -- "$(dirname -- "$replaced_plugin")"
  mv -- "$LIVE_PLUGIN" "$replaced_plugin"
fi
mv -- "$plugin_stage" "$LIVE_PLUGIN"
plugin_stage=""

GSETTINGS_BACKEND=memory noctalia msg plugins enable samh/quiet-core >/dev/null

config_parent=$(dirname -- "$LIVE_CONFIG")
mkdir -p -- "$config_parent"
config_stage=$(mktemp "$config_parent/.quiet-core.preview.XXXXXX")
cp -- "$PROPOSED_CONFIG" "$config_stage"
if [[ -e $LIVE_CONFIG ]]; then
  chmod --reference="$LIVE_CONFIG" "$config_stage"
else
  chmod 600 "$config_stage"
fi
mv --force -- "$config_stage" "$LIVE_CONFIG"
config_stage=""

if [[ -f $LIVE_SETTINGS ]]; then
  settings_parent=$(dirname -- "$LIVE_SETTINGS")
  settings_stage=$(mktemp "$settings_parent/.quiet-core.preview.XXXXXX")
  python3 - "$LIVE_SETTINGS" "$settings_stage" <<'PY'
import sys

source_path, destination_path = sys.argv[1:]
with open(source_path, encoding="utf-8") as source:
    lines = source.readlines()

result = []
inside_bar_default = False
for line in lines:
    if line.rstrip("\n") == "[bar.default]":
        inside_bar_default = True
        continue
    if inside_bar_default and line.startswith("["):
        inside_bar_default = False
    if not inside_bar_default:
        result.append(line)

with open(destination_path, "w", encoding="utf-8") as destination:
    destination.writelines(result)
PY
  chmod --reference="$LIVE_SETTINGS" "$settings_stage"
  mv --force -- "$settings_stage" "$LIVE_SETTINGS"
  settings_stage=""
fi

GSETTINGS_BACKEND=memory noctalia msg color-scheme-set wallpaper soft >/dev/null
GSETTINGS_BACKEND=memory noctalia msg config-reload >/dev/null
GSETTINGS_BACKEND=memory noctalia msg status >/dev/null

plugins_output=$(GSETTINGS_BACKEND=memory noctalia msg plugins list)
if ! rg -q '^samh/quiet-core .* enabled' <<<"$plugins_output"; then
  echo "Quiet Core plugin did not become enabled." >&2
  exit 1
fi

GSETTINGS_BACKEND=memory noctalia msg panel-open samh/quiet-core:dashboard >/dev/null
status_output=$(GSETTINGS_BACKEND=memory noctalia msg status)
python3 -c '
import json, sys
status = json.load(sys.stdin)
if not status.get("panelOpen") or status.get("activePanelId") != "samh/quiet-core:dashboard":
    raise SystemExit("Quiet Core panel did not open")
' <<<"$status_output"

umask 077
mkdir -p -- "$PREVIEW_DIR"
printf 'snapshot=%s\nstarted_utc=%s\n' \
  "$snapshot_id" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >"$PREVIEW_MARKER"

trap - ERR

printf '\nQuiet Core preview is active.\n'
printf 'Rollback snapshot: %s\n' "$snapshot_id"
printf 'To restore the previous desktop: task desktop:preview:rollback\n'
printf 'No process or service was restarted.\n'
