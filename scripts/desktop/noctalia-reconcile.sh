#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091  # Resolved relative to this script at runtime.
source "$SCRIPT_DIR/lib.sh"

usage() {
  cat <<'EOF'
Usage: noctalia-reconcile.sh [--authored PATH] [--runtime PATH]

Compare ownership of approved stable Noctalia settings without printing their
values. Sensitive and transient configuration namespaces are not inspected.
EOF
}

authored_path="$HOME/.config/noctalia/config.toml"
runtime_path="$HOME/.local/state/noctalia/settings.toml"

while (($# > 0)); do
  case $1 in
    --authored | --runtime)
      option=$1
      if (($# < 2)); then
        echo "$option requires a path." >&2
        exit 2
      fi
      if [[ $option == "--authored" ]]; then
        authored_path=$2
      else
        runtime_path=$2
      fi
      shift
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
unset option

desktop_require_safe_home

printf '[noctalia ownership]\n'
printf 'authored           %s\n' "$(desktop_display_path "$authored_path")"
printf 'runtime override   %s\n' "$(desktop_display_path "$runtime_path")"
printf '\n%-20s %s\n' 'ownership' 'setting'

python3 - "$authored_path" "$runtime_path" <<'PY'
import pathlib
import sys
import tomllib


MISSING = object()


def load(path_text):
    path = pathlib.Path(path_text)
    if not path.is_file():
        return {}
    try:
        with path.open("rb") as stream:
            return tomllib.load(stream)
    except (OSError, tomllib.TOMLDecodeError) as error:
        print(f"Cannot parse {path.name}: {type(error).__name__}", file=sys.stderr)
        raise SystemExit(1) from error


def nested(data, path):
    current = data
    for key in path:
        if not isinstance(current, dict) or key not in current:
            return MISSING
        current = current[key]
    return current


def status(authored, runtime):
    if authored is MISSING and runtime is MISSING:
        return "unset"
    if authored is MISSING:
        return "runtime-only"
    if runtime is MISSING:
        return "authored-only"
    if authored == runtime:
        return "same"
    return "override-different"


authored = load(sys.argv[1])
runtime = load(sys.argv[2])

# This is intentionally an allowlist. Do not add calendar, location, accounts,
# commands, paths, or arbitrary plugin settings without a redaction review.
stable_keys = (
    ("theme", "mode"),
    ("theme", "source"),
    ("theme", "wallpaper_scheme"),
    ("theme", "templates", "builtin_ids"),
    ("plugins", "enabled"),
    ("wallpaper", "default", "path"),
)
stable_scopes = (
    ("accessibility",),
    ("bar",),
    ("dock",),
    ("shell", "panel"),
    ("system", "monitor"),
    ("widget",),
)

for path in (*stable_keys, *stable_scopes):
    ownership = status(nested(authored, path), nested(runtime, path))
    if ownership != "unset":
        print(f"{ownership:<20} {'.'.join(path)}")
PY

printf '\nValues and sensitive/transient namespaces were intentionally omitted.\n'
printf 'No configuration or process state was changed.\n'
