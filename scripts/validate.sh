#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

bash -n \
  "$REPO_ROOT/bootstrap.sh" \
  "$REPO_ROOT/scripts/install-packages-linux.sh" \
  "$REPO_ROOT/setup-macos.sh"

python3 -m json.tool "$REPO_ROOT/home/private_dot_config/nvim/lazyvim.json" >/dev/null
python3 -m json.tool "$REPO_ROOT/home/private_dot_config/nvim/lazy-lock.json" >/dev/null
python3 -m json.tool "$REPO_ROOT/home/private_dot_config/nvim/dot_neoconf.json" >/dev/null
python3 -m json.tool "$REPO_ROOT/home/private_dot_config/oh-my-posh/dev.omp.json" >/dev/null

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck \
    "$REPO_ROOT/bootstrap.sh" \
    "$REPO_ROOT/scripts/install-packages-linux.sh"
fi

if command -v shfmt >/dev/null 2>&1; then
  shfmt -d -i 2 -ci \
    "$REPO_ROOT/bootstrap.sh" \
    "$REPO_ROOT/scripts/install-packages-linux.sh"
fi

if command -v mise >/dev/null 2>&1; then
  MISE_GLOBAL_CONFIG_FILE="$REPO_ROOT/home/private_dot_config/mise/config.toml" \
    mise config ls >/dev/null
fi

if command -v task >/dev/null 2>&1; then
  task --list >/dev/null
fi

if rg -n --glob '!setup-macos.sh' --glob '!README.md' --glob '!SETUP.md' \
  --glob '!scripts/validate.sh' \
  'claudecode|claude-code' "$REPO_ROOT"; then
  echo "Active configuration still references Claude Code." >&2
  exit 1
fi

if command -v chezmoi >/dev/null 2>&1; then
  TEST_HOME=$(mktemp -d)
  trap 'rm -rf -- "$TEST_HOME"' EXIT
  TEST_CHEZMOI_HOME="$TEST_HOME/.config/chezmoi"
  TEST_CHEZMOI_CONFIG="$TEST_CHEZMOI_HOME/stark10-dotfiles.toml"
  mkdir -p "$TEST_CHEZMOI_HOME" "$TEST_HOME/.tmux/plugins/tpm"
  printf 'sourceDir = "/preserve/default/config"\n[data]\nmarker = "preserve-me"\n' \
    >"$TEST_CHEZMOI_HOME/chezmoi.toml"
  HOME="$TEST_HOME" chezmoi --config "$TEST_CHEZMOI_CONFIG" init \
    --source "$REPO_ROOT" \
    --promptString "Git author name=Validation User" \
    --promptString "Git author email=validation@example.invalid"
  HOME="$TEST_HOME" chezmoi --config "$TEST_CHEZMOI_CONFIG" execute-template \
    --source "$REPO_ROOT" \
    <"$REPO_ROOT/home/dot_zshrc.tmpl" >"$TEST_HOME/zshrc"
  zsh -n "$TEST_HOME/zshrc"
  HOME="$TEST_HOME" XDG_CONFIG_HOME="$TEST_HOME/.config" \
    "$REPO_ROOT/bootstrap.sh" --yes --skip-packages --skip-tools >/dev/null
  rg -q 'marker = "preserve-me"' "$TEST_CHEZMOI_HOME/chezmoi.toml"
  test -f "$TEST_HOME/.gitconfig"
  rg -q '^\s*name = Validation User$' "$TEST_HOME/.gitconfig"
  rg -q '^\s*email = validation@example.invalid$' "$TEST_HOME/.gitconfig"
  test -f "$TEST_HOME/.config/nvim/lua/plugins/omp.lua"
  test -f "$TEST_HOME/.config/mise/config.toml"
fi

echo "Validation passed."
