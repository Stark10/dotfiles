#!/usr/bin/env bash
# =============================================================================
# macOS Dev Environment Setup Script
# Original macOS installer (retired).
# Description: Replicates a full macOS development environment with tools,
#              shell config, editor, and dotfiles.
# Usage: ./setup-macos.sh [--dry-run]
# =============================================================================
set -euo pipefail

cat >&2 <<'EOF'
setup-macos.sh is retired because its dry-run mode can still write files.

Use the safe, cross-platform installer instead:
  ./bootstrap.sh --dry-run
  ./bootstrap.sh --yes
EOF
exit 2

# ─── Colors & Logging ────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
    echo -e "${YELLOW}[DRY RUN MODE]${NC} No changes will be made."
fi

info()    { echo -e "${BLUE}[INFO]${NC}    $*"; }
success() { echo -e "${GREEN}[✓]${NC}     $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}    $*"; }
error()   { echo -e "${RED}[✗]${NC}     $*" >&2; }

run() {
    if $DRY_RUN; then
        echo -e "${YELLOW}[DRY RUN]${NC} $*"
    else
        eval "$@"
    fi
}

# ─── Pre-flight Checks ──────────────────────────────────────────────────────
info "Checking pre-requisites..."

if [[ "$(uname)" != "Darwin" ]]; then
    error "This script is designed for macOS only."
    exit 1
fi

if ! command -v xcode-select &>/dev/null; then
    error "Xcode command-line tools not found. Run: xcode-select --install"
    exit 1
fi
success "Xcode command-line tools found."

# =============================================================================
# SECTION 1: Homebrew & Casks
# =============================================================================
info "=== Installing Homebrew ==="

if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    success "Homebrew installed."
else
    success "Homebrew already installed: $(brew --version | head -1)"
fi

# Tap useful formulae repos
run brew tap homebrew/cask-fonts

# Install Homebrew casks (GUI apps)
info "Installing Homebrew casks..."
BREW_CASKS=(
    ghostty
    font-meslo-lg-nerd-font
    claude-code
    codex
    gcloud-cli
    google-cloud-sdk
)

for cask in "${BREW_CASKS[@]}"; do
    if ! brew list --cask "$cask" &>/dev/null; then
        run brew install --cask "$cask"
        success "Cask installed: $cask"
    else
        success "Cask already installed: $cask"
    fi
done

# Install Homebrew formulae (CLI tools)
info "Installing Homebrew formulae..."
BREW_FORMULAE=(
    # Core utilities
    eza fd fzf ripgrep tree-sitter zoxide
    # Version managers
    python@3.13
    # Runtime / languages
    rust
    go-task
    # Databases
    postgresql@14 redis
    # Dev tools
    tmux lazygit gh herdr supabase
    # Shell / prompt
    oh-my-posh
    # Completion & syntax
    zsh-autosuggestions zsh-syntax-highlighting
    # Libraries (dependencies that might not pull automatically)
    openssl@3
    # Build tools
    cmake
    # Misc
    ffmpeg
)

for formula in "${BREW_FORMULAE[@]}"; do
    if ! brew list "$formula" &>/dev/null; then
        run brew install "$formula"
        success "Formula installed: $formula"
    else
        success "Formula already installed: $formula"
    fi
done

# Clean up old Homebrew downloads
run brew cleanup -s
success "Homebrew cleanup done."

# =============================================================================
# SECTION 2: Shell & Prompt
# =============================================================================
info "=== Setting up Shell ==="

# Set default shell to zsh
CURRENT_SHELL=$(dscl . -read /Users/"$(whoami)" UserShell 2>/dev/null | awk '{print $2}')
if [[ "$CURRENT_SHELL" != "/bin/zsh" ]]; then
    info "Setting default shell to zsh..."
    run chsh -s /bin/zsh
    success "Default shell set to zsh."
else
    success "Default shell is already zsh."
fi

# Install Oh My Zsh (if not already installed)
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    info "Installing Oh My Zsh..."
    run git clone https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
    success "Oh My Zsh installed."
else
    success "Oh My Zsh already installed."
fi

# Install NVM
if [[ ! -d "$HOME/.nvm" ]]; then
    info "Installing NVM..."
    run curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    success "NVM installed."
else
    success "NVM already installed."
fi

# Install Bun
if [[ ! -d "$HOME/.bun" ]]; then
    info "Installing Bun..."
    run curl -fsSL https://bun.sh/install | bash
    success "Bun installed."
else
    success "Bun already installed."
fi

# =============================================================================
# SECTION 3: Shell Configuration (.zshrc)
# =============================================================================
info "=== Writing .zshrc ==="

cat > "$HOME/.zshrc" << 'ZSHRC_EOF'
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Theme (robbyrussell is the default OMZ theme; prompt is handled by oh-my-posh)
ZSH_THEME="robbyrussell"

# Plugins
plugins=(git)

source $ZSH/oh-my-zsh.sh

# ─── History Setup ───────────────────────────────────────────────────────────
HISTFILE=$HOME/.zhistory
SAVEHIST=1000
HISTSIZE=999
setopt share_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_verify

# History search with arrow keys
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# ─── Zsh Plugins ─────────────────────────────────────────────────────────────
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ─── Zoxide (better cd) ─────────────────────────────────────────────────────
eval "$(zoxide init zsh)"

# ─── Eza (better ls) ────────────────────────────────────────────────────────
alias ls="eza --icons=always -a"

# ─── Python & Pip Aliases ────────────────────────────────────────────────────
alias python="python3"
alias pip="pip3"

# ─── NVM ─────────────────────────────────────────────────────────────────────
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# ─── Bun ─────────────────────────────────────────────────────────────────────
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"

# ─── LM Studio CLI (optional) ───────────────────────────────────────────────
export PATH="$PATH:$HOME/.lmstudio/bin"

# ─── Oh My Posh (Night Owl theme) ───────────────────────────────────────────
eval "$(oh-my-posh init zsh --config ~/night-owl.omp.json)"
ZSHRC_EOF

success ".zshrc written."

# =============================================================================
# SECTION 4: Oh My Posh Theme (Night Owl)
# =============================================================================
info "=== Writing Oh My Posh config ==="

cat > "$HOME/night-owl.omp.json" << 'POSH_EOF'
{
  "$schema": "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
  "blocks": [
    {
      "alignment": "left",
      "segments": [
        {
          "background": "#21c7a8",
          "foreground": "#011627",
          "leading_diamond": "\u256d\u2500\ue0b6",
          "options": { "windows": "\ue62a" },
          "style": "diamond",
          "template": " {{ if .WSL }}WSL at {{ end }}{{.Icon}}  ",
          "trailing_diamond": "\ue0b0",
          "type": "os"
        },
        {
          "background": "#ef5350",
          "foreground": "#ffeb95",
          "powerline_symbol": "\ue0b0",
          "style": "powerline",
          "template": " \uf292 ",
          "type": "root"
        },
        {
          "background": "#82AAFF",
          "foreground": "#011627",
          "powerline_symbol": "\ue0b0",
          "leading_powerline_symbol": "\ue0d7",
          "options": {
            "folder_icon": "\uf07c ",
            "folder_separator_icon": "<#011627>\ue0b1</> ",
            "home_icon": " \ueb06 ",
            "style": "agnoster"
          },
          "style": "powerline",
          "template": "{{ path .Path .Location }}",
          "type": "path"
        },
        {
          "background": "#addb67",
          "background_templates": [
            "{{ if or (.Working.Changed) (.Staging.Changed) }}#e4cf6a{{ end }}",
            "{{ if and (gt .Ahead 0) (gt .Behind 0) }}#f78c6c{{ end }}",
            "{{ if gt .Ahead 0 }}#C792EA{{ end }}",
            "{{ if gt .Behind 0 }}#c792ea{{ end }}"
          ],
          "foreground": "#011627",
          "powerline_symbol": "\ue0b0",
          "options": {
            "branch_icon": "\ue725 ",
            "fetch_status": true,
            "fetch_upstream_icon": true,
            "mapped_branches": { "feat/*": "🚀 ", "bug/*": "🐛 " }
          },
          "style": "powerline",
          "template": " {{ .UpstreamIcon }} {{ .HEAD }}{{if .BranchStatus }} {{ .BranchStatus }}{{ end }}{{ if .Working.Changed }} \uf044 {{ .Working.String }}{{ end }}{{ if and (.Working.Changed) (.Staging.Changed) }} |{{ end }}{{ if .Staging.Changed }} \uf046 {{ .Staging.String }}{{ end }}{{ if gt .StashCount 0 }} \ueb4b {{ .StashCount }}{{ end }} ",
          "type": "git"
        },
        {
          "background": "#575656",
          "foreground": "#d6deeb",
          "leading_diamond": "\ue0d7",
          "options": { "style": "roundrock", "threshold": 0 },
          "style": "diamond",
          "template": " {{ .FormattedMs }}",
          "trailing_diamond": "\ue0b4",
          "type": "executiontime"
        }
      ],
      "type": "prompt"
    },
    {
      "alignment": "right",
      "overflow": "break",
      "segments": [
        {
          "background": "#d6deeb",
          "foreground": "#011627",
          "leading_diamond": "\ue0b6",
          "style": "diamond",
          "template": "\uf489  {{ .Name }} ",
          "trailing_diamond": "\ue0d6",
          "type": "shell"
        },
        {
          "background": "#8f43f3",
          "foreground": "#ffffff",
          "leading_diamond": "\ue0b2",
          "style": "diamond",
          "template": "\ue266 {{ round .PhysicalPercentUsed .Precision }}% ",
          "trailing_diamond": "\ue0d6",
          "type": "sysinfo"
        },
        {
          "background": "#ffffff",
          "foreground": "#ce092f",
          "leading_diamond": "\ue0b2",
          "style": "diamond",
          "template": "\ue753 {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} ",
          "trailing_diamond": "\ue0d6",
          "type": "angular"
        },
        {
          "background": "#565656",
          "foreground": "#faa029",
          "leading_diamond": "\ue0b2",
          "style": "diamond",
          "template": "\ue641 {{ .CurrentDate | date .Format }}",
          "trailing_diamond": "\ue0b4",
          "type": "time"
        }
      ],
      "type": "prompt"
    },
    {
      "alignment": "left",
      "newline": true,
      "segments": [
        {
          "foreground": "#21c7a8",
          "style": "plain",
          "template": "\u2570\u2500",
          "type": "text"
        },
        {
          "foreground": "#22da6e",
          "foreground_templates": ["{{ if gt .Code 0 }}#ef5350{{ end }}"],
          "options": { "always_enabled": true },
          "style": "plain",
          "template": "\ue285\ue285",
          "type": "status"
        }
      ],
      "type": "prompt"
    }
  ],
  "console_title_template": "{{ .Folder }}",
  "final_space": true,
  "transient_prompt": {
    "background": "transparent",
    "foreground": "#d6deeb",
    "template": "\ue285 "
  },
  "version": 4
}
POSH_EOF

success "Oh My Posh config written."

# =============================================================================
# SECTION 5: Git Configuration
# =============================================================================
info "=== Setting up Git ==="

# Git author identity is intentionally configured per user by chezmoi.
run git config --global core.autocrlf "input"
run git config --global credential.helper osxkeychain
run git config --global filter.lfs.clean "git-lfs clean -- %f"
run git config --global filter.lfs.smudge "git-lfs smudge -- %f"
run git config --global filter.lfs.process "git-lfs filter-process"
run git config --global filter.lfs.required true

# Install git-lfs if not present
if ! command -v git-lfs &>/dev/null; then
    run brew install git-lfs
    run git lfs install
    success "git-lfs installed and initialized."
else
    success "git-lfs already installed."
fi

success "Git config written."

# =============================================================================
# SECTION 6: Tmux Configuration
# =============================================================================
info "=== Writing .tmux.conf ==="

cat > "$HOME/.tmux.conf" << 'TMUX_EOF'
set -g default-terminal "tmux-256color"
set -ag terminal-overrides ",xterm-256color:RGB"

# Prefix: Ctrl-a instead of Ctrl-b
set -g prefix C-a
unbind C-b
bind-key C-a send-prefix

# Window splitting
unbind %
bind | split-window -h
unbind '"'
bind - split-window -v

# Reload config
unbind r
bind r source-file ~/.tmux.conf

# Resize with hjkl
bind j resize-pane -D 5
bind k resize-pane -U 5
bind l resize-pane -R 5
bind h resize-pane -L 5
bind -r m resize-pane -Z

# New window in current directory
bind M-c attach-session -c "#{pane_current_path}"

# Mouse support
set -g mouse on

# Vi mode in copy mode
set-window-option -g mode-keys vi

# Vi-style copy mode bindings
bind-key -T copy-mode-vi 'v' send -X begin-selection
bind-key -T copy-mode-vi 'y' send -X copy-selection
unbind -T copy-mode-vi MouseDragEnd1Pane

# Reduce escape delay for Neovim
set -sg escape-time 10

# ─── TPM (Tmux Plugin Manager) ──────────────────────────────────────────────
set -g @plugin 'tmux-plugins/tpm'

# ─── Tmux Plugins ───────────────────────────────────────────────────────────
set -g @plugin 'christoomey/vim-tmux-navigator'
set -g @plugin 'fabioluciano/tmux-tokyo-night'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'

set -g @resurrect-capture-pane-contents 'on'
set -g @continuum-restore 'on'

# Initialize TPM (keep this line at the very bottom)
run '~/.tmux/plugins/tpm/tpm'
TMUX_EOF

success ".tmux.conf written."

# =============================================================================
# SECTION 7: Neovim Configuration (LazyVim)
# =============================================================================
info "=== Setting up Neovim (LazyVim) ==="

NVIM_DIR="$HOME/.config/nvim"

# Create directory structure
run mkdir -p "$NVIM_DIR/lua/config"
run mkdir -p "$NVIM_DIR/lua/plugins"

# init.lua
cat > "$NVIM_DIR/init.lua" << 'NVIM_INIT_EOF'
-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
NVIM_INIT_EOF

# config/autocmds.lua
cat > "$NVIM_DIR/lua/config/autocmds.lua" << 'AUTOCMD_EOF'
-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here with `vim.api.nvim_create_autocmd`
AUTOCMD_EOF

# config/keymaps.lua
cat > "$NVIM_DIR/lua/config/keymaps.lua" << 'KEYMAPS_EOF'
-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
KEYMAPS_EOF

# config/options.lua
cat > "$NVIM_DIR/lua/config/options.lua" << 'OPTIONS_EOF'
-- Options are automatically loaded before lazy.nvim startup
-- Default options: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Put swap files in a dedicated directory to avoid .swp clutter
vim.opt.directory = vim.fn.stdpath("state") .. "/swap//"
OPTIONS_EOF

# config/lazy.lua
cat > "$NVIM_DIR/lua/config/lazy.lua" << 'LAZY_EOF'
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    { import = "plugins" },
  },
  defaults = {
    lazy = false,
    version = false,
  },
  install = { colorscheme = { "tokyonight", "habamax" } },
  checker = { enabled = true, notify = false },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
LAZY_EOF

# plugins/example.lua
cat > "$NVIM_DIR/lua/plugins/example.lua" << 'EX_EOF'
-- since this is just an example spec, don't actually load anything here
if true then return {} end

return {
  -- add gruvbox
  { "ellisonleao/gruvbox.nvim" },

  -- Configure LazyVim to load gruvbox
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "gruvbox" },
  },

  -- change some telescope options
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      { "<leader>fp", function() require("telescope.builtin").find_files({ cwd = require("lazy.core.config").options.root }) end, desc = "Find Plugin File" },
    },
    opts = {
      defaults = {
        layout_strategy = "horizontal",
        layout_config = { prompt_position = "top" },
        sorting_strategy = "ascending",
        winblend = 0,
      },
    },
  },

  -- add treesitter parsers
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash", "html", "javascript", "json", "lua",
        "markdown", "markdown_inline", "python", "query",
        "regex", "tsx", "typescript", "vim", "yaml",
      },
    },
  },

  -- install tools via mason
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "stylua", "shellcheck", "shfmt", "flake8",
      },
    },
  },
}
EX_EOF

# plugins/neo-tree.lua
cat > "$NVIM_DIR/lua/plugins/neo-tree.lua" << 'NEOTREE_EOF'
return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      filesystem = {
        filtered_items = {
          visible = false,
          hide_dotfiles = false,
          hide_gitignored = false,
          hide_hidden = false,
          hide_by_name = {},
          never_show = {},
        },
      },
    },
  },
}
NEOTREE_EOF

# plugins/neo-tree-config.lua
cat > "$NVIM_DIR/lua/plugins/neo-tree-config.lua" << 'NEOTREE_CFG_EOF'
return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      filtered_items = {
        hide_dotfiles = false,
      },
    },
  },
}
NEOTREE_CFG_EOF

# plugins/snacks.lua
cat > "$NVIM_DIR/lua/plugins/snacks.lua" << 'SNACKS_EOF'
return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = { hidden = true, ignored = true },
          files = { hidden = true, ignored = true },
        },
      },
    },
  },
}
SNACKS_EOF

# plugins/telescope.lua
cat > "$NVIM_DIR/lua/plugins/telescope.lua" << 'TELESCOPE_EOF'
return {
  {
    "nvim-telescope/telescope.nvim",
    opts = {
      defaults = {
        file_ignore_patterns = { "^.git/" },
      },
      pickers = {
        find_files = { hidden = true },
      },
    },
  },
}
TELESCOPE_EOF

# lazyvim.json
cat > "$NVIM_DIR/lazyvim.json" << 'LAZYVIM_EOF'
{
  "extras": [
    "lazyvim.plugins.extras.ai.claudecode",
    "lazyvim.plugins.extras.ai.copilot",
    "lazyvim.plugins.extras.coding.yanky",
    "lazyvim.plugins.extras.editor.fzf",
    "lazyvim.plugins.extras.editor.outline",
    "lazyvim.plugins.extras.editor.overseer",
    "lazyvim.plugins.extras.editor.refactoring",
    "lazyvim.plugins.extras.editor.telescope",
    "lazyvim.plugins.extras.lang.astro",
    "lazyvim.plugins.extras.lang.docker",
    "lazyvim.plugins.extras.lang.git",
    "lazyvim.plugins.extras.lang.json",
    "lazyvim.plugins.extras.lang.markdown",
    "lazyvim.plugins.extras.lang.python",
    "lazyvim.plugins.extras.lang.rust",
    "lazyvim.plugins.extras.lang.sql",
    "lazyvim.plugins.extras.lang.svelte",
    "lazyvim.plugins.extras.lang.tailwind",
    "lazyvim.plugins.extras.lang.toml",
    "lazyvim.plugins.extras.lang.typescript",
    "lazyvim.plugins.extras.lang.yaml",
    "lazyvim.plugins.extras.lang.zig"
  ],
  "install_version": 8,
  "version": 8
}
LAZYVIM_EOF

# .gitignore for nvim config
cat > "$NVIM_DIR/.gitignore" << 'GITIGNORE_EOF'
lazy-lock.json
GITIGNORE_EOF

# .neoconf.json
cat > "$NVIM_DIR/.neoconf.json" << 'NEOCONF_EOF'
{
  "neodev": {
    "library": {
      "enabled": true,
      "plugins": true
    }
  },
  "neoconf": {
    "plugins": {
      "lua_ls": {}
    }
  }
}
NEOCONF_EOF

# stylua.toml
cat > "$NVIM_DIR/stylua.toml" << 'STYLUA_EOF'
indent_type = "Spaces"
indent_width = 2
quote_style = "AutoPreferSingle"
call_parentheses = "None"
STYLUA_EOF

success "Neovim (LazyVim) config written."

# =============================================================================
# SECTION 8: Alacritty Configuration (if used)
# =============================================================================
info "=== Writing Alacritty config ==="

ALACRITTY_DIR="$HOME/.config/alacritty"
run mkdir -p "$ALACRITTY_DIR/themes/themes"

# Download coolnight theme
if [[ ! -f "$ALACRITTY_DIR/themes/themes/coolnight.toml" ]]; then
    info "Downloading coolnight theme..."
    run curl -fsSL "https://raw.githubusercontent.com/Codecat/coolnight/main/alacritty/coolnight.toml" -o "$ALACRITTY_DIR/themes/themes/coolnight.toml"
    success "Coolnight theme downloaded."
else
    success "Coolnight theme already exists."
fi

# Write alacritty config
cat > "$ALACRITTY_DIR/alacritty.toml" << 'ALACRITTY_EOF'
general.import = [
    "~/.config/alacritty/themes/themes/coolnight.toml"
]

[env]
TERM = "xterm-256color"

[window]
padding.x = 10
padding.y = 10
decorations = "Buttonless"
opacity = 0.7
blur = true
option_as_alt = "Both"

[font]
normal.family = "MesloLGS Nerd Font Mono"
size = 12
ALACRITTY_EOF

success "Alacritty config written."

# =============================================================================
# SECTION 9: Ghostty Configuration (if used)
# =============================================================================
info "=== Writing Ghostty config ==="

GHOSTTY_DIR="$HOME/.config/ghostty"
run mkdir -p "$GHOSTTY_DIR"

cat > "$GHOSTTY_DIR/config" << 'GHOSTTY_EOF'
# Ghostty configuration
font-family = MesloLGS Nerd Font Mono
font-size = 12
theme = Catppuccin.Mocha
window-padding-x = 10
window-padding-y = 10
window-decoration = false
background-opacity = 0.85
GHOSTTY_EOF

success "Ghostty config written."

# =============================================================================
# SECTION 10: Global NPM Packages
# =============================================================================
info "=== Installing Global NPM Packages ==="

NPM_GLOBAL=(
    @angular/cli
    @kilocode/cli
    corepack
    n
)

for pkg in "${NPM_GLOBAL[@]}"; do
    if ! npm list -g "$pkg" &>/dev/null 2>&1; then
        run sudo npm install -g "$pkg" 2>/dev/null || run npm install -g "$pkg"
        success "NPM package installed: $pkg"
    else
        success "NPM package already installed: $pkg"
    fi
done

# =============================================================================
# SECTION 11: Rust / Cargo Setup
# =============================================================================
info "=== Setting up Rust ==="

if command -v rustup &>/dev/null; then
    info "Rustup already installed. Updating toolchain..."
    run rustup update stable 2>/dev/null || true
    success "Rust toolchain updated."
else
    info "Installing Rust via rustup..."
    run curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    success "Rust installed."
fi

# Source cargo env
if [[ -f "$HOME/.cargo/env" ]]; then
    run . "$HOME/.cargo/env"
fi

# Install common cargo crates
info "Installing common cargo crates..."
CARGO_CRATES=(
    trunk
    cargo-watch
)

for crate in "${CARGO_CRATES[@]}"; do
    if ! cargo list "$crate" &>/dev/null 2>&1; then
        run cargo install "$crate" 2>/dev/null || warn "Failed to install cargo crate: $crate"
        success "Cargo crate installed: $crate"
    else
        success "Cargo crate already installed: $crate"
    fi
done

# =============================================================================
# SECTION 12: Python Setup
# =============================================================================
info "=== Setting up Python ==="

# Install uv (fast Python package manager)
if ! command -v uv &>/dev/null; then
    info "Installing uv..."
    run curl -LsSf https://astral.sh/uv/install.sh | sh
    success "uv installed."
else
    success "uv already installed."
fi

# =============================================================================
# SECTION 13: SSH Setup (generate if no keys exist)
# =============================================================================
info "=== SSH Setup ==="

if [[ ! -d "$HOME/.ssh" ]]; then
    run mkdir -p "$HOME/.ssh"
    run chmod 700 "$HOME/.ssh"
    info "Created ~/.ssh directory."
fi

if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
    warn "No SSH key found. You'll need to generate one or copy yours."
    info "To generate a new key: ssh-keygen -t ed25519 -C 'your_email@example.com'"
else
    success "SSH key already exists."
fi

# =============================================================================
# DONE
# =============================================================================
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Setup Complete! 🎉${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
info "Next steps:"
echo "  1. Open a NEW terminal (or run: exec zsh)"
echo "  2. Install tmux plugins: tmux and press 'prefix + I'"
echo "  3. Open Neovim: nvim (plugins will install on first launch)"
echo "  4. Set up NVM node versions: nvm install --lts"
echo "  5. Copy your SSH keys if you haven't already"
echo ""
info "Files created/modified:"
echo "  - ~/.zshrc"
echo "  - ~/.tmux.conf"
echo "  - ~/.config/nvim/ (LazyVim config)"
echo "  - ~/.config/alacritty/alacritty.toml"
echo "  - ~/.config/ghostty/config"
echo "  - ~/night-owl.omp.json"
echo ""
