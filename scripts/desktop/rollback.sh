#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091  # Resolved relative to this script at runtime.
source "$SCRIPT_DIR/lib.sh"

usage() {
  cat <<'EOF'
Usage: rollback.sh [--snapshot ID|latest] [--dry-run] [--yes]

Restore only the allowlisted desktop paths recorded by snapshot.sh. A
pre-rollback snapshot is created automatically. This script never restarts,
logs out, stops, or signals a process, but watched configuration files may be
reloaded by a running shell. Run it only when a live reload is acceptable.
EOF
}

snapshot_ref="latest"
dry_run=false
assume_yes=false

while (($# > 0)); do
  case $1 in
    --snapshot)
      if (($# < 2)); then
        echo "--snapshot requires an ID or latest." >&2
        exit 2
      fi
      snapshot_ref=$2
      shift
      ;;
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

if [[ $snapshot_ref == "latest" ]]; then
  latest_marker="$DESKTOP_SNAPSHOT_DIR/latest"
  if [[ ! -L $latest_marker ]]; then
    echo "No latest snapshot marker exists." >&2
    exit 1
  fi
  snapshot_ref=$(readlink -- "$latest_marker")
fi

if [[ ! $snapshot_ref =~ ^[0-9]{8}T[0-9]{6}Z(-[0-9]+)?$ ]]; then
  echo "Invalid snapshot ID: $snapshot_ref" >&2
  exit 2
fi

snapshot_path="$DESKTOP_SNAPSHOT_DIR/$snapshot_ref"
manifest_path="$snapshot_path/manifest.tsv"
if [[ ! -f $manifest_path ]]; then
  echo "Snapshot manifest not found: $manifest_path" >&2
  exit 1
fi

printf 'Rollback source: %s\n' "$(desktop_display_path "$snapshot_path")"
printf 'Planned changes:\n'
while IFS=$'\t' read -r state relative_path; do
  if ! desktop_path_is_managed "$relative_path"; then
    echo "Refusing unrecognized path in manifest: $relative_path" >&2
    exit 1
  fi
  if [[ ! $state =~ ^(missing|file|directory|symlink)$ ]]; then
    echo "Refusing invalid state in manifest: $state" >&2
    exit 1
  fi
  printf '  %-10s %s\n' "$state" "$(desktop_display_path "$HOME/$relative_path")"
done <"$manifest_path"

if [[ $dry_run == true ]]; then
  printf 'Dry run complete. Nothing was changed.\n'
  exit 0
fi

if [[ $assume_yes == false ]]; then
  if [[ ! -t 0 ]]; then
    echo "Refusing non-interactive rollback without --yes." >&2
    exit 1
  fi
  printf 'Restore these paths? Watched files may reload automatically. [y/N] '
  read -r confirmation
  if [[ ! $confirmation =~ ^[Yy]$ ]]; then
    echo "Rollback cancelled."
    exit 0
  fi
fi

pre_rollback_id=$("$SCRIPT_DIR/snapshot.sh" --quiet | tail -n 1)
pre_rollback_path="$DESKTOP_SNAPSHOT_DIR/$pre_rollback_id"
replaced_path="$pre_rollback_path/replaced-during-rollback"
staging_path="$pre_rollback_path/restore-staging"
mkdir -p -- "$replaced_path" "$staging_path"

while IFS=$'\t' read -r state relative_path; do
  target_path="$HOME/$relative_path"
  saved_path="$snapshot_path/payload/$relative_path"
  replaced_target="$replaced_path/$relative_path"
  staged_target="$staging_path/$relative_path"

  if [[ -e $target_path || -L $target_path ]]; then
    mkdir -p -- "$(dirname -- "$replaced_target")"
    mv -- "$target_path" "$replaced_target"
  fi

  if [[ $state != "missing" ]]; then
    if [[ ! -e $saved_path && ! -L $saved_path ]]; then
      echo "Snapshot payload is missing: $saved_path" >&2
      echo "Current target was preserved at: $replaced_target" >&2
      exit 1
    fi
    mkdir -p -- "$(dirname -- "$staged_target")"
    cp -a -- "$saved_path" "$staged_target"
    mkdir -p -- "$(dirname -- "$target_path")"
    mv -- "$staged_target" "$target_path"
  fi
done <"$manifest_path"

printf 'Rollback restored snapshot %s.\n' "$snapshot_ref"
printf 'Pre-rollback recovery snapshot: %s\n' "$pre_rollback_id"
printf 'No processes were restarted, stopped, or signalled.\n'
