#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Validation requires '$1'. Run the bootstrap first." >&2
    exit 1
  fi
}

for required_command in chezmoi mise python3 pwsh rg shellcheck shfmt task yq zsh; do
  require_command "$required_command"
done
unset required_command

bash -n \
  "$REPO_ROOT/bootstrap.sh" \
  "$REPO_ROOT/scripts/install-packages-linux.sh" \
  "$REPO_ROOT/setup-macos.sh"

python3 -m json.tool "$REPO_ROOT/home/private_dot_config/nvim/lazyvim.json" >/dev/null
python3 -m json.tool "$REPO_ROOT/home/private_dot_config/nvim/lazy-lock.json" >/dev/null
python3 -m json.tool "$REPO_ROOT/home/private_dot_config/nvim/dot_neoconf.json" >/dev/null
python3 -m json.tool "$REPO_ROOT/home/private_dot_config/oh-my-posh/dev.omp.json" >/dev/null

shellcheck \
  "$REPO_ROOT/bootstrap.sh" \
  "$REPO_ROOT/scripts/install-packages-linux.sh"

shfmt -d -i 2 -ci \
  "$REPO_ROOT/bootstrap.sh" \
  "$REPO_ROOT/scripts/install-packages-linux.sh"

MISE_GLOBAL_CONFIG_FILE="$REPO_ROOT/home/private_dot_config/mise/config.toml" \
  mise config ls >/dev/null

task --list >/dev/null
PG19_SUMMARY=$(task --summary pg19:up PG19_PORT=5420)
rg -q 'port=5420' <<<"$PG19_SUMMARY"
rg -q 'publish "127.0.0.1:5420:5432"' <<<"$PG19_SUMMARY"
unset PG19_SUMMARY

if rg -n --glob '!setup-macos.sh' --glob '!README.md' --glob '!SETUP.md' \
  --glob '!scripts/validate.sh' --glob '!scripts/validate.ps1' \
  'claudecode|claude-code' "$REPO_ROOT"; then
  echo "Active configuration still references Claude Code." >&2
  exit 1
fi

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
if [[ $(uname -s) == Darwin ]]; then
  rg -q 'postgresql@18/bin' "$TEST_HOME/zshrc"
fi
HOME="$TEST_HOME" XDG_CONFIG_HOME="$TEST_HOME/.config" \
  "$REPO_ROOT/bootstrap.sh" --yes --skip-packages --skip-tools >/dev/null
rg -q 'marker = "preserve-me"' "$TEST_CHEZMOI_HOME/chezmoi.toml"
test -f "$TEST_HOME/.gitconfig"
rg -q '^\s*name = Validation User$' "$TEST_HOME/.gitconfig"
rg -q '^\s*email = validation@example.invalid$' "$TEST_HOME/.gitconfig"
python3 -c 'import sys, tomllib; data = tomllib.load(open(sys.argv[1], "rb")); assert data["window"]["opacity"] == 0.7; assert data["window"]["decorations"] == ("Buttonless" if sys.platform == "darwin" else "None"); assert data["colors"]["primary"]["background"] == "#011423"' \
  "$TEST_HOME/.config/alacritty/alacritty.toml"
test -f "$TEST_HOME/.config/nvim/lua/plugins/omp.lua"
test -f "$TEST_HOME/.config/mise/config.toml"
test ! -e "$TEST_HOME/.config/alacritty/alacritty.yml"

SKIP_DRY_RUN=$(HOME="$TEST_HOME" XDG_CONFIG_HOME="$TEST_HOME/.config" \
  "$REPO_ROOT/bootstrap.sh" --dry-run --skip-packages --skip-dotfiles)
if rg -q 'nvim --headless' <<<"$SKIP_DRY_RUN"; then
  echo "The skip-dotfiles dry run still attempts to sync Neovim." >&2
  exit 1
fi
unset SKIP_DRY_RUN

python3 -c 'import sys, tomllib; data = tomllib.load(open(sys.argv[1], "rb")); assert data["window"]["decorations"] == "None"; assert data["window"]["opacity"] == 0.7' \
  "$REPO_ROOT/home/AppData/Roaming/alacritty/alacritty.toml"
yq -e '.window.decorations == "none" and .window.opacity == 0.7 and .colors.primary.background == "#011423"' \
  "$REPO_ROOT/home/private_dot_config/alacritty/alacritty.yml" >/dev/null

echo "Validation passed."
