#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
fi

run() {
  if $DRY_RUN; then
    printf '[dry-run]'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

if [[ ! -r /etc/os-release ]]; then
  echo "Unable to identify this Linux distribution: /etc/os-release is missing." >&2
  exit 1
fi

# shellcheck source=/dev/null
source /etc/os-release
DISTRO="${ID:-unknown}"

if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
  SUDO=()
elif command -v sudo >/dev/null 2>&1; then
  SUDO=(sudo)
else
  echo "sudo is required to install system packages." >&2
  exit 1
fi

case "$DISTRO" in
  ubuntu | debian | linuxmint | pop)
    run "${SUDO[@]}" apt-get update
    run "${SUDO[@]}" apt-get install -y \
      build-essential ca-certificates curl git git-lfs postgresql redis-server shellcheck shfmt tmux unzip zip zsh
    ;;
  fedora)
    run "${SUDO[@]}" dnf install -y \
      ca-certificates curl gcc gcc-c++ git git-lfs make postgresql-server redis ShellCheck shfmt tmux unzip zip zsh
    ;;
  arch | manjaro)
    run "${SUDO[@]}" pacman -Syu --needed --noconfirm \
      base-devel ca-certificates curl git git-lfs postgresql redis shellcheck shfmt tmux unzip zip zsh
    ;;
  *)
    echo "Unsupported Linux distribution '$DISTRO'." >&2
    echo "Install curl, git, git-lfs, a compiler toolchain, zsh, and tmux, then rerun with --skip-packages." >&2
    exit 1
    ;;
esac

if ! command -v oh-my-posh >/dev/null 2>&1; then
  if $DRY_RUN; then
    echo "[dry-run] install oh-my-posh into $HOME/.local/bin"
  else
    curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin"
  fi
fi
