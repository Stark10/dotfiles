#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
CHEZMOI_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/chezmoi"
CHEZMOI_CONFIG="$CHEZMOI_CONFIG_HOME/stark10-dotfiles.toml"
CHEZMOI_TEMP_DIR=""
DRY_RUN=false
SKIP_PACKAGES=false
SKIP_TOOLS=false
SKIP_DOTFILES=false
ASSUME_YES=false

usage() {
  cat <<'EOF'
Usage: ./bootstrap.sh [options]

Options:
  --dry-run        Print every planned mutation without changing the machine.
  --skip-packages  Do not install OS packages.
  --skip-tools     Do not install mise-managed tools or Neovim plugins.
  --skip-dotfiles  Do not apply chezmoi-managed configuration.
  --yes            Apply dotfiles without an interactive confirmation.
  -h, --help       Show this help.
EOF
}

while (($#)); do
  case "$1" in
    --dry-run) DRY_RUN=true ;;
    --skip-packages) SKIP_PACKAGES=true ;;
    --skip-tools) SKIP_TOOLS=true ;;
    --skip-dotfiles) SKIP_DOTFILES=true ;;
    --yes) ASSUME_YES=true ;;
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

run() {
  if $DRY_RUN; then
    printf '[dry-run]'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

find_command() {
  local name=$1
  local fallback=$2
  if command -v "$name" >/dev/null 2>&1; then
    command -v "$name"
  elif [[ -x "$fallback" ]]; then
    printf '%s\n' "$fallback"
  else
    return 1
  fi
}

cleanup() {
  if [[ -n "$CHEZMOI_TEMP_DIR" && -d "$CHEZMOI_TEMP_DIR" ]]; then
    rm -rf -- "$CHEZMOI_TEMP_DIR"
  fi
}
trap cleanup EXIT

OS=$(uname -s)
case "$OS" in
  Darwin | Linux) ;;
  *)
    echo "Unsupported operating system '$OS'. Use bootstrap.ps1 on Windows." >&2
    exit 1
    ;;
esac

echo "Bootstrapping the development environment for $OS"

if ! $SKIP_PACKAGES; then
  if [[ "$OS" == "Darwin" ]]; then
    if ! command -v brew >/dev/null 2>&1; then
      if $DRY_RUN; then
        echo "[dry-run] install Homebrew"
      else
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        if [[ -x /opt/homebrew/bin/brew ]]; then
          eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -x /usr/local/bin/brew ]]; then
          eval "$(/usr/local/bin/brew shellenv)"
        fi
      fi
    fi
    run brew bundle --file "$REPO_ROOT/packages/Brewfile"
  else
    if $DRY_RUN; then
      "$REPO_ROOT/scripts/install-packages-linux.sh" --dry-run
    else
      "$REPO_ROOT/scripts/install-packages-linux.sh"
    fi
  fi
fi

if ! CHEZMOI_BIN=$(find_command chezmoi "$HOME/.local/bin/chezmoi"); then
  if $DRY_RUN; then
    CHEZMOI_BIN="$HOME/.local/bin/chezmoi"
    echo "[dry-run] install chezmoi at $CHEZMOI_BIN"
  else
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
    CHEZMOI_BIN="$HOME/.local/bin/chezmoi"
  fi
fi

if ! MISE_BIN=$(find_command mise "$HOME/.local/bin/mise"); then
  if $DRY_RUN; then
    MISE_BIN="$HOME/.local/bin/mise"
    echo "[dry-run] install mise at $MISE_BIN"
  else
    curl https://mise.run | sh
    MISE_BIN="$HOME/.local/bin/mise"
  fi
fi

if ! $SKIP_DOTFILES; then
  if $DRY_RUN; then
    if [[ -f "$CHEZMOI_CONFIG" ]]; then
      echo "[dry-run] refresh isolated chezmoi config at $CHEZMOI_CONFIG"
    else
      echo "[dry-run] generate isolated chezmoi config at $CHEZMOI_CONFIG"
    fi
    echo "[dry-run] $CHEZMOI_BIN --config $CHEZMOI_CONFIG diff --source $REPO_ROOT"
    echo "[dry-run] $CHEZMOI_BIN --config $CHEZMOI_CONFIG apply --source $REPO_ROOT"
  else
    CHEZMOI_TEMP_DIR=$(mktemp -d)
    ACTIVE_CHEZMOI_CONFIG="$CHEZMOI_TEMP_DIR/chezmoi.toml"
    if [[ -f "$CHEZMOI_CONFIG" ]]; then
      cp "$CHEZMOI_CONFIG" "$ACTIVE_CHEZMOI_CONFIG"
    fi
    "$CHEZMOI_BIN" --config "$ACTIVE_CHEZMOI_CONFIG" init --source "$REPO_ROOT"
    "$CHEZMOI_BIN" --config "$ACTIVE_CHEZMOI_CONFIG" diff --source "$REPO_ROOT"
    if ! $ASSUME_YES; then
      read -r -p "Apply the dotfile changes above? [y/N] " reply
      [[ "$reply" =~ ^[Yy]$ ]] || {
        echo "Dotfile application skipped."
        SKIP_DOTFILES=true
      }
    fi
    if ! $SKIP_DOTFILES; then
      "$CHEZMOI_BIN" --config "$ACTIVE_CHEZMOI_CONFIG" apply --source "$REPO_ROOT"
      mkdir -p "$CHEZMOI_CONFIG_HOME"
      install -m 600 "$ACTIVE_CHEZMOI_CONFIG" "$CHEZMOI_CONFIG"
    fi
  fi
fi

if $SKIP_DOTFILES; then
  export MISE_GLOBAL_CONFIG_FILE="$REPO_ROOT/home/private_dot_config/mise/config.toml"
else
  export MISE_GLOBAL_CONFIG_FILE="$HOME/.config/mise/config.toml"
fi
export DOTFILES_NVIM_BOOTSTRAP="$REPO_ROOT/scripts/wait-for-mason.lua"
if ! $SKIP_TOOLS; then
  run "$MISE_BIN" --yes install
  if ! $SKIP_DOTFILES; then
    if ! $DRY_RUN; then
      "$MISE_BIN" exec -- nvim --headless "+Lazy! restore" +qa
      "$MISE_BIN" exec -- nvim --headless "+lua dofile(vim.env.DOTFILES_NVIM_BOOTSTRAP)"
    else
      echo "[dry-run] $MISE_BIN exec -- nvim --headless +Lazy! restore +qa"
      echo "[dry-run] $MISE_BIN exec -- nvim --headless +lua dofile(vim.env.DOTFILES_NVIM_BOOTSTRAP)"
    fi
  else
    echo "Neovim plugin sync skipped because dotfiles were not applied."
  fi
fi

if $DRY_RUN; then
  echo "[dry-run] git lfs install"
else
  git lfs install >/dev/null 2>&1 || true
fi
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
  run git clone --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

echo "Bootstrap complete. Start the configured shell with: exec zsh"
