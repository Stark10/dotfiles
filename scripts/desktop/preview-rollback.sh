#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091  # Resolved relative to this script at runtime.
source "$SCRIPT_DIR/lib.sh"

PREVIEW_DIR="$DESKTOP_STATE_DIR/previews"
PREVIEW_MARKER="$PREVIEW_DIR/active"

usage() {
  cat <<'EOF'
Usage: preview-rollback.sh [--dry-run] [--yes]

Restore the snapshot recorded for the active Quiet Core preview and reload
Noctalia configuration through IPC. No process or service is restarted.
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

if [[ ! -f $PREVIEW_MARKER ]]; then
  echo "No active Quiet Core preview marker exists." >&2
  exit 1
fi

snapshot_id=$(awk -F= '$1 == "snapshot" { print $2; exit }' "$PREVIEW_MARKER")
if [[ ! $snapshot_id =~ ^[0-9]{8}T[0-9]{6}Z(-[0-9]+)?$ ]]; then
  echo "Invalid snapshot ID in preview marker." >&2
  exit 1
fi

rollback_args=(--snapshot "$snapshot_id")
if [[ $dry_run == true ]]; then
  rollback_args+=(--dry-run)
elif [[ $assume_yes == true ]]; then
  rollback_args+=(--yes)
fi

"$SCRIPT_DIR/rollback.sh" "${rollback_args[@]}"

if [[ $dry_run == true ]]; then
  exit 0
fi

if ! GSETTINGS_BACKEND=memory noctalia msg config-reload >/dev/null; then
  echo "Files were restored, but Noctalia IPC reload was unavailable." >&2
  echo "The restored config will be used on the next normal shell start." >&2
fi

archive_dir="$PREVIEW_DIR/completed"
mkdir -p -- "$archive_dir"
mv -- "$PREVIEW_MARKER" "$archive_dir/${snapshot_id}.rolled-back"

printf 'Quiet Core preview rolled back to snapshot %s.\n' "$snapshot_id"
printf 'No process or service was restarted.\n'
