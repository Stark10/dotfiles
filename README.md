# Cross-platform development environment

This repo installs the same terminal and LazyVim baseline on macOS, Linux, and
Windows. It uses three deliberately separate layers:

- **native packages** for OS-level prerequisites and desktop terminals;
- **mise** for portable developer tools and pinned runtimes;
- **chezmoi** for rendering and applying the dotfiles in `home/`.

The Neovim AI workflow uses
[Sidekick.nvim](https://github.com/folke/sidekick.nvim) with
[Oh My Pi](https://github.com/can1357/oh-my-pi) (`omp`). Claude Code is no
longer part of the active setup. GitHub Copilot completion remains enabled,
while Sidekick's separate next-edit-suggestion feature is disabled.

## Quick start

Clone the repo, preview the changes, and only then apply them.

### macOS or Linux

```bash
git clone https://github.com/Stark10/dotfiles.git
cd dotfiles
./bootstrap.sh --dry-run
./bootstrap.sh --yes
```

The script cannot replace its parent shell. When it finishes, run `exec zsh`
to enter the configured shell. To make zsh the login shell permanently, run
`chsh -s "$(command -v zsh)"`, then sign out and back in.

### Windows

Windows requires `winget` (provided by Microsoft App Installer) and Git before
the repository can be cloned. On a stock machine with `winget`, install Git,
restart PowerShell, and then run:

```powershell
winget install --id Git.Git --exact
git clone https://github.com/Stark10/dotfiles.git
Set-Location dotfiles
.\bootstrap.ps1 -DryRun
.\bootstrap.ps1 -Yes
```

The bootstrap scripts install packages, preview the chezmoi diff, apply the
dotfiles, install mise-managed tools, and sync LazyVim plugins. Without
`--yes`/`-Yes`, the real run asks before chezmoi changes the home directory.
On first use, chezmoi also asks for the Git author name and email to place in
the machine-local configuration, so people using a fork do not inherit mine.
The installer stores this repo's data in
`~/.config/chezmoi/stark10-dotfiles.toml`; it does not replace chezmoi's normal
config, existing source directory, or encryption identity.

Useful options:

| Unix | PowerShell | Effect |
| --- | --- | --- |
| `--dry-run` | `-DryRun` | Print planned mutations without applying them |
| `--skip-packages` | `-SkipPackages` | Skip Homebrew, distro, or winget packages |
| `--skip-tools` | `-SkipTools` | Skip mise tools and Neovim plugin sync |
| `--skip-dotfiles` | `-SkipDotfiles` | Skip chezmoi diff and apply |

## LazyVim and Oh My Pi

The active configuration is in
`home/private_dot_config/nvim/lua/plugins/omp.lua`. The main bindings are:

| Binding | Action |
| --- | --- |
| `<leader>aa` | Toggle an OMP terminal for the current project |
| `<leader>as` | Choose or create an AI CLI session |
| `<leader>af` | Send the current file to the active CLI |
| `<leader>av` | Send the visual selection |
| `<leader>ap` | Open Sidekick's prompt picker |
| `<C-.>` | Focus the active CLI, or hide it when already focused |

Sidekick opens the CLI in a normal Neovim split, so standard window commands
resize it. Because OMP starts in terminal-input mode, first press `<C-q>` (the
Sidekick stop-input binding) or `<C-\><C-n>`, then use `<C-w>>` and `<C-w><`
to change width, `<C-w>+` and `<C-w>-` to change height, `<C-w>|` to maximize
width, `<C-w>_` to maximize height, or `<C-w>=` to equalize all windows. Prefix
a resize with a count for a larger step, such as `10<C-w>>`.

OMP authentication and sessions live outside this repository. Run `omp` once
and follow its setup flow on a new machine. Never commit `~/.omp/agent`, API
keys, `.env` files, or SSH keys.

Homebrew installs the configured Nerd Font on macOS. On Linux or Windows, run
`oh-my-posh font install meslo` once if prompt icons are missing; font selection
is a host UI setting and cannot be made portable across every terminal.

Alacritty reproduces the Coolnight palette, `0.7` opacity, background blur,
10-pixel padding, and Meslo font without requiring a separate theme checkout.
macOS uses its native buttonless transparent title bar; Linux and Windows use
no window decorations for the closest borderless equivalent.

## Platform coverage

| Layer | macOS | Linux | Windows |
| --- | --- | --- | --- |
| Native packages | Homebrew `packages/Brewfile` | apt, dnf, or pacman | winget |
| Tool versions | mise | mise | mise |
| Dotfiles | chezmoi templates | chezmoi templates | chezmoi templates |
| Shell | zsh | zsh | PowerShell 7 |
| Terminals | Ghostty + Alacritty | Ghostty + Alacritty config | Windows Terminal + Alacritty |

The portable mise layer also installs Codex, Go, CMake, FFmpeg, gcloud, and the
Supabase CLI. The normal macOS package is PostgreSQL 18; Linux uses the selected
distribution's packaged PostgreSQL. Redis is also a native Unix package. These
services are not automatically provisioned as Windows services.

Linux package automation currently supports Debian/Ubuntu derivatives, Fedora,
and Arch/Manjaro. On another distribution, install the
prerequisites listed by the script and rerun with `--skip-packages`.

## PostgreSQL 19 graph lab

PostgreSQL 19 is currently a beta, so it is kept separate from the normal host
database. With Docker running, Task starts the official `postgres:19beta2`
image on loopback port `5419` with a persistent named volume:

```bash
task pg19:up
task pg19:version
task pg19:psql
```

Connect with
`postgresql://postgres:postgres@127.0.0.1:5419/graph_lab`. The deliberately
simple credentials are only for this loopback-bound local lab. Run
`task pg19:stop` when finished; its data volume is retained. PostgreSQL 19's
[SQL/PGQ property-graph support](https://www.postgresql.org/docs/19/ddl-property-graphs.html)
exposes relational tables as property graphs through `CREATE PROPERTY GRAPH`
and queries them with `GRAPH_TABLE`.

## Repository layout

```text
home/                         chezmoi source state
  private_dot_config/nvim/            LazyVim configuration
  private_dot_config/mise/config.toml portable tools and runtimes
packages/Brewfile             macOS native packages
packages/windows.ps1          Windows native packages
scripts/install-packages-linux.sh
Taskfile.yml                   local checks and PostgreSQL 19 lab
bootstrap.sh                  macOS/Linux entrypoint
bootstrap.ps1                 Windows entrypoint
```

## Updating the setup

Edit files under `home/`, then preview and apply them:

```bash
chezmoi --config ~/.config/chezmoi/stark10-dotfiles.toml diff --source "$PWD"
chezmoi --config ~/.config/chezmoi/stark10-dotfiles.toml apply --source "$PWD"
```

Use `mise upgrade` when you intentionally want newer `latest` tools. Pinned
runtime and OMP versions only change when `home/private_dot_config/mise/config.toml`
changes.

Run the local checks before publishing:

```bash
task
```

The retired `setup-macos.sh` is retained for history, but it refuses to run by
default because its old dry-run path was not read-only.
