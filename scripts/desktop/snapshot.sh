#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091  # Resolved relative to this script at runtime.
source "$SCRIPT_DIR/lib.sh"

usage() {
  cat <<'EOF'
Usage: snapshot.sh [--dry-run] [--quiet]

Create a private, targeted snapshot of desktop configuration. The script does
not reload, restart, signal, or stop any process.
EOF
}

dry_run=false
quiet=false

while (($# > 0)); do
  case $1 in
    --dry-run)
      dry_run=true
      ;;
    --quiet)
      quiet=true
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
umask 077

snapshot_id=$(date -u +%Y%m%dT%H%M%SZ)
snapshot_path="$DESKTOP_SNAPSHOT_DIR/$snapshot_id"
suffix=0
while [[ -e $snapshot_path ]]; do
  suffix=$((suffix + 1))
  snapshot_path="$DESKTOP_SNAPSHOT_DIR/$snapshot_id-$suffix"
done
snapshot_id=${snapshot_path##*/}

if [[ $dry_run == true ]]; then
  printf 'Would create snapshot: %s\n' "$(desktop_display_path "$snapshot_path")"
else
  mkdir -p -- "$snapshot_path/payload"
  : >"$snapshot_path/manifest.tsv"
fi

for relative_path in "${DESKTOP_MANAGED_PATHS[@]}"; do
  source_path="$HOME/$relative_path"
  destination_path="$snapshot_path/payload/$relative_path"
  state="missing"

  if [[ -L $source_path ]]; then
    state="symlink"
  elif [[ -d $source_path ]]; then
    state="directory"
  elif [[ -f $source_path ]]; then
    state="file"
  fi

  if [[ $quiet == false || $dry_run == true ]]; then
    printf '%-10s %s\n' "$state" "$(desktop_display_path "$source_path")"
  fi

  if [[ $dry_run == false ]]; then
    printf '%s\t%s\n' "$state" "$relative_path" >>"$snapshot_path/manifest.tsv"
    if [[ $state != "missing" ]]; then
      mkdir -p -- "$(dirname -- "$destination_path")"
      cp -a -- "$source_path" "$destination_path"
    fi
  fi
done
unset destination_path relative_path source_path state

if [[ $dry_run == false ]]; then
  printf 'schema=1\ncreated_utc=%s\n' "$snapshot_id" >"$snapshot_path/metadata"
  if [[ -e $DESKTOP_SNAPSHOT_DIR/latest && ! -L $DESKTOP_SNAPSHOT_DIR/latest ]]; then
    echo "Refusing to replace non-symlink latest marker: $DESKTOP_SNAPSHOT_DIR/latest" >&2
    exit 1
  fi
  ln -sfn -- "$snapshot_id" "$DESKTOP_SNAPSHOT_DIR/latest"
  if [[ $quiet == false ]]; then
    printf 'Snapshot created: %s\n' "$(desktop_display_path "$snapshot_path")"
  fi
fi

printf '%s\n' "$snapshot_id"
