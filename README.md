# dotfiles

One-command setup script to replicate my macOS development environment on a new machine.

## Quick Start

```bash
# Clone and run
git clone https://github.com/Stark10/dotfiles.git
cd dotfiles
chmod +x setup-macos.sh
./setup-macos.sh
```

Or dry-run first to preview what it'll do:

```bash
./setup-macos.sh --dry-run
```

## What Gets Installed

### Package Manager
- **Homebrew** — macOS package manager

### GUI Apps (Casks)
| App | Purpose |
|-----|---------|
| [Ghostty](https://ghostty.org) | Terminal emulator (primary) |
| [Alacritty](https://alacritty.org) | GPU-accelerated terminal (fallback) |
| [Claude Code](https://claude.ai/code) | AI coding assistant |
| [Codex CLI](https://github.com/openai/codex) | OpenAI's CLI |
| [Google Cloud SDK](https://cloud.google.com/sdk) | gcloud CLI |

### CLI Tools (Formulae)
| Tool | Purpose |
|------|---------|
| [eza](https://github.com/eza-community/eza) | Modern `ls` replacement |
| [fd](https://github.com/sharkdp/fd) | Modern `find` replacement |
| [fzf](https://github.com/junegunn/fzf) | Fuzzy finder |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | Modern `grep` replacement |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | Smarter `cd` |
| [lazygit](https://github.com/jesseduffield/lazygit) | TUI git client |
| [tmux](https://github.com/tmux/tmux) | Terminal multiplexer |
| [tree-sitter](https://tree-sitter.github.io) | Incremental parsing |
| [gh](https://github.com/cli/cli) | GitHub CLI |
| [herdr](https://github.com/HerdrUp/herdr) | Database client |
| [supabase](https://supabase.com) | Supabase CLI |
| [go-task](https://go-task.github.io) | Task runner |
| [ffmpeg](https://ffmpeg.org) | Media processing |
| [openssl](https://openssl.org) | TLS library |
| [cmake](https://cmake.org) | Build system |
| [postgresql@14](https://postgresql.org) | PostgreSQL 14 |
| [redis](https://redis.io) | Redis server |
| [oh-my-posh](https://ohmyposh.dev) | Prompt theme engine |
| [python@3.13](https://python.org) | Python 3.13 |
| [rust](https://rust-lang.org) | Rust via Homebrew |
| [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) | Shell autosuggestions |
| [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) | Shell syntax highlighting |

### Version Managers & Runtimes
| Tool | Purpose |
|------|---------|
| [NVM](https://github.com/nvm-sh/nvm) | Node.js version manager |
| [Bun](https://bun.sh) | Fast JS/TS runtime |
| [Rustup](https://rustup.rs) | Rust version manager |
| [uv](https://astral.sh/uv) | Fast Python package manager |

### Shell & Prompt
| Tool | Purpose |
|------|---------|
| **Zsh** + **Oh My Zsh** | Shell + framework |
| **Oh My Posh** (Night Owl theme) | Cross-shell prompt with rich info |
| **Powerlevel10k** instant prompt | Fast P10k loading |

### Editor
| Tool | Purpose |
|------|---------|
| **Neovim** + **LazyVim** | Modern Neovim distro |
| [lazy.nvim](https://github.com/folke/lazy.nvim) | Plugin manager |
| [neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim) | File explorer |
| [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) | Fuzzy finder |
| [snacks.nvim](https://github.com/folke/snacks.nvim) | Utility plugins |
| [yanky.nvim](https://github.com/gbprod/yanky.nvim) | Better paste buffer |
| [overseer.nvim](https://github.com/stevearc/overseer.nvim) | Task runner |
| [fzf-lua](https://github.com/ibhagun/fzf-lua) | Fzf integration |
| [outline.nvim](https://github.com/hedyhli/outline.nvim) | LSP symbol outline |
| [refactoring.nvim](https://github.com/LazyVim/lazyvim.plugins.extras.editor.refactoring) | Code refactoring |

#### LazyVim Language Extras
Rust, TypeScript, JavaScript, TSX, Python, Svelte, Astro, Docker, JSON, YAML, TOML, SQL, Git, Markdown, Zig

### Terminal Multiplexer (tmux)
| Plugin | Purpose |
|--------|---------|
| [TPM](https://github.com/tmux-plugins/tpm) | Plugin manager |
| [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) | Vim ↔ tmux pane navigation |
| [tmux-tokyo-night](https://github.com/fabioluciano/tmux-tokyo-night) | Tokyo Night colors |
| [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) | Session persistence |
| [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum) | Auto-save sessions |

### Git Configuration
- User: `Samwise` / `sam@deeptree.co.nz`
- LFS enabled
- `osxkeychain` credential helper
- `gh`-backed GitHub auth

### Dotfiles Written
| File | Description |
|------|-------------|
| `~/.zshrc` | Shell config, aliases, plugins, prompt |
| `~/.tmux.conf` | Tmux config with plugin setup |
| `~/.config/nvim/` | LazyVim Neovim config |
| `~/.config/alacritty/alacritty.toml` | Alacritty terminal config |
| `~/.config/ghostty/config` | Ghostty terminal config |
| `~/night-owl.omp.json` | Oh My Posh Night Owl prompt theme |

## Post-Setup Steps

After running the script, do these manually:

1. **Restart your terminal** — open a new window or run `exec zsh`
2. **Install tmux plugins** — open tmux and press `<prefix> + I` (default `Ctrl-b` then `I`)
3. **Install Neovim plugins** — open `nvim` and run `:Lazy sync`
4. **Set up NVM** — `nvm install --lts` and `nvm use --lts`
5. **Copy SSH keys** — if you have existing keys, copy them to `~/.ssh/`
6. **Install tmux plugins** — run `~/.tmux/plugins/tpm/bin/install_plugins`

## Customization

Edit these files after setup to personalize:

- `~/.zshrc` — aliases, env vars, plugins
- `~/night-owl.omp.json` — prompt appearance
- `~/.config/nvim/lazyvim.json` — Neovim extras
- `~/.config/nvim/lua/plugins/` — custom Neovim plugins
- `~/.tmux.conf` — tmux keybindings and plugins

## Troubleshooting

**Oh My Posh not working?** Make sure you're using a Nerd Font (MesloLGS Nerd Font Mono is installed via Homebrew).

**Neovim plugins not loading?** Run `:Lazy sync` inside Neovim.

**tmux plugins not loading?** Run `~/.tmux/plugins/tpm/bin/install_plugins` inside tmux.

**Brew cask install fails?** Run `brew doctor` and fix any issues first.
