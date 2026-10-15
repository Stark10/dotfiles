#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)
PROTOTYPE_DIR="$REPO_ROOT/desktop/prototypes/noctalia/quiet-core"
PROTOTYPE_CONFIG="$REPO_ROOT/desktop/prototypes/noctalia/config.toml"
PROPOSED_CONFIG="$REPO_ROOT/desktop/proposed/noctalia/config.toml"
HYPRLAND_PROTOTYPE="$REPO_ROOT/desktop/prototypes/hyprland/quiet-core.lua"

for required_command in python3 rg shellcheck shfmt; do
  if ! command -v "$required_command" >/dev/null 2>&1; then
    echo "Desktop validation requires '$required_command'." >&2
    exit 1
  fi
done
unset required_command

desktop_scripts=(
  "$SCRIPT_DIR/audit.sh"
  "$SCRIPT_DIR/lib.sh"
  "$SCRIPT_DIR/noctalia-reconcile.sh"
  "$SCRIPT_DIR/performance.sh"
  "$SCRIPT_DIR/preview-rollback.sh"
  "$SCRIPT_DIR/preview.sh"
  "$SCRIPT_DIR/rollback.sh"
  "$SCRIPT_DIR/snapshot.sh"
  "$SCRIPT_DIR/validate.sh"
)

bash -n "${desktop_scripts[@]}"
shellcheck "${desktop_scripts[@]}"
shfmt -d -i 2 -ci "${desktop_scripts[@]}"

if rg -n \
  '(^|[[:space:]])(kill|killall|pkill|reboot|shutdown|poweroff)([[:space:]]|$)|systemctl[[:space:]]+--user[[:space:]]+(start|stop|restart|enable|disable)' \
  "$SCRIPT_DIR/audit.sh" \
  "$SCRIPT_DIR/lib.sh" \
  "$SCRIPT_DIR/noctalia-reconcile.sh" \
  "$SCRIPT_DIR/performance.sh" \
  "$SCRIPT_DIR/rollback.sh" \
  "$SCRIPT_DIR/snapshot.sh"; then
  echo "Desktop foundation scripts contain a process or service mutation." >&2
  exit 1
fi

python3 - "$PROTOTYPE_DIR/plugin.toml" <<'PY'
import sys
import tomllib

with open(sys.argv[1], "rb") as source:
    plugin = tomllib.load(source)

assert plugin["id"] == "samh/quiet-core"
assert plugin["plugin_api"] == 24
assert plugin["dependencies"] == []
assert len(plugin.get("widget", [])) == 1
assert len(plugin.get("panel", [])) == 1
panel = plugin["panel"][0]
assert panel["width"] == 1180
assert panel["height"] == 760
assert panel["placement"] == "floating"
PY

python3 "$SCRIPT_DIR/validate_profiles.py" "$REPO_ROOT"

if command -v luac >/dev/null 2>&1; then
  luac -p "$HYPRLAND_PROTOTYPE"
else
  echo "luac is unavailable; skipped optional Hyprland prototype syntax check."
fi

if rg -n \
  'noctalia\.(run|runAsync|runInTerminal|http|httpStream|writeFile)|systemctl|llama-control|wallpaper-(set|next|previous)|color-scheme-set|templates-apply' \
  "$PROTOTYPE_DIR"/*.luau; then
  echo "Quiet Core visual prototype contains an operational API call." >&2
  exit 1
fi

test_home=$(mktemp -d)
trap 'rm -rf -- "$test_home"' EXIT
test_state="$test_home/.local/state"

if command -v noctalia >/dev/null 2>&1; then
  mkdir -p \
    "$test_home/.config" \
    "$test_home/.local/state" \
    "$test_home/.runtime"
  chmod 700 "$test_home/.runtime"
  env \
    HOME="$test_home" \
    XDG_CONFIG_HOME="$test_home/.config" \
    XDG_STATE_HOME="$test_home/.local/state" \
    XDG_RUNTIME_DIR="$test_home/.runtime" \
    GSETTINGS_BACKEND=memory \
    noctalia config validate "$PROTOTYPE_CONFIG"
  env \
    HOME="$test_home" \
    XDG_CONFIG_HOME="$test_home/.config" \
    XDG_STATE_HOME="$test_home/.local/state" \
    XDG_RUNTIME_DIR="$test_home/.runtime" \
    GSETTINGS_BACKEND=memory \
    noctalia config validate "$PROPOSED_CONFIG"
  env \
    HOME="$test_home" \
    XDG_CONFIG_HOME="$test_home/.config" \
    XDG_STATE_HOME="$test_home/.local/state" \
    XDG_RUNTIME_DIR="$test_home/.runtime" \
    GSETTINGS_BACKEND=memory \
    noctalia plugins lint "$PROTOTYPE_DIR"
else
  echo "Noctalia is unavailable; skipped its optional offline plugin lint."
fi

mkdir -p \
  "$test_home/.config/hypr/config" \
  "$test_home/.config/noctalia" \
  "$test_home/.local/share/noctalia/plugins/llama-control"
printf 'original hypr config\n' >"$test_home/.config/hypr/hyprland.lua"
printf 'original module\n' >"$test_home/.config/hypr/config/variables.lua"
printf '[theme]\nmode = "dark"\nsource = "wallpaper"\nwallpaper_scheme = "soft"\n' \
  >"$test_home/.config/noctalia/config.toml"
printf 'original plugin\n' \
  >"$test_home/.local/share/noctalia/plugins/llama-control/plugin.toml"
printf '[theme]\nmode = "light"\nwallpaper_scheme = "soft"\n' \
  >"$test_home/runtime-fixture.toml"

reconcile_output=$(HOME="$test_home" \
  "$SCRIPT_DIR/noctalia-reconcile.sh" \
  --runtime "$test_home/runtime-fixture.toml")
rg -q 'override-different[[:space:]]+theme.mode' <<<"$reconcile_output"
rg -q 'authored-only[[:space:]]+theme.source' <<<"$reconcile_output"
rg -q 'same[[:space:]]+theme.wallpaper_scheme' <<<"$reconcile_output"

snapshot_dry_run=$(HOME="$test_home" XDG_STATE_HOME="$test_state" \
  "$SCRIPT_DIR/snapshot.sh" --dry-run --quiet)
rg -q 'Would create snapshot' <<<"$snapshot_dry_run"

snapshot_id=$(HOME="$test_home" XDG_STATE_HOME="$test_state" \
  "$SCRIPT_DIR/snapshot.sh" --quiet | tail -n 1)
[[ $snapshot_id =~ ^[0-9]{8}T[0-9]{6}Z(-[0-9]+)?$ ]]
test -f "$test_state/stark10-desktop/snapshots/$snapshot_id/manifest.tsv"

printf 'changed hypr config\n' >"$test_home/.config/hypr/hyprland.lua"
mkdir -p "$test_home/.config/btop/themes"
printf 'new generated theme\n' >"$test_home/.config/btop/themes/noctalia.theme"

rollback_dry_run=$(HOME="$test_home" XDG_STATE_HOME="$test_state" \
  "$SCRIPT_DIR/rollback.sh" --snapshot "$snapshot_id" --dry-run)
rg -q 'Dry run complete' <<<"$rollback_dry_run"
rg -q '^changed hypr config$' "$test_home/.config/hypr/hyprland.lua"

HOME="$test_home" XDG_STATE_HOME="$test_state" \
  "$SCRIPT_DIR/rollback.sh" --snapshot "$snapshot_id" --yes >/dev/null
rg -q '^original hypr config$' "$test_home/.config/hypr/hyprland.lua"
rg -q '^original module$' "$test_home/.config/hypr/config/variables.lua"
test ! -e "$test_home/.config/btop/themes/noctalia.theme"

audit_output=$(HOME="$test_home" XDG_STATE_HOME="$test_state" \
  "$SCRIPT_DIR/audit.sh")
rg -q 'Audit complete' <<<"$audit_output"

performance_output=$(HOME="$test_home" "$SCRIPT_DIR/performance.sh")
rg -q 'Performance snapshot complete' <<<"$performance_output"

echo "Desktop validation passed."
