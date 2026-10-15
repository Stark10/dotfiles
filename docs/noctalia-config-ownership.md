# Noctalia configuration ownership

Status: reviewed proposal; no live changes
Date: 2026-09-03

This document defines which configuration layer owns each Noctalia concern for
Quiet Core. It is based on the redacted audit and ownership comparison; it does
not copy `settings.toml`, calendar/location data, or other runtime state into
the repository.

## Current layers

- Authored base: `~/.config/noctalia/config.toml`
- GUI/runtime override: `~/.local/state/noctalia/settings.toml`
- Local custom plugin: `~/.local/share/noctalia/plugins/llama-control/`
- Repo-only design study: `desktop/prototypes/noctalia/config.toml`
- Repo-only visual plugin: `desktop/prototypes/noctalia/quiet-core/`

Noctalia loads authored TOML first and runtime settings last, so a runtime key
with the same path wins. Quiet Core must not try to keep both copies in sync.

## Ownership table

| Concern | Current state | Version-one owner | Reconciliation |
| --- | --- | --- | --- |
| UI scale | Authored only | Machine-local authored data | Preserve `1.20`; do not make it a shared visual token |
| Bar layout and styling | Authored only | Repository | Replace with the reviewed quiet-rail configuration after live acceptance |
| Built-in widget styling | Authored only | Repository | Preserve functionality; map colours/geometry to Quiet Core tokens |
| Llama widget declaration | Authored only | Repository | Preserve `samh/llama-control:status`; keep operational plugin separately owned |
| Screenshot commands | Authored only | Machine-local integration | Preserve unchanged unless explicitly redesigned |
| Session actions | Authored only | Repository with safety review | Preserve current actions; do not invoke them during apply or validation |
| Polkit and app launch integration | Authored only | Machine-local integration | Preserve current settings and test separately from visual changes |
| Panel placement/effects | Authored only | Repository | Adopt the validated soft-glass/floating proposal |
| GPU polling interval | Authored only | Machine-local authored data | Preserve; exclude from visual profile changes |
| Theme mode/source/scheme | Same in both layers today | Repository profile | At apply time remove only the overlapping runtime keys, then apply `Calm` (`soft`) initially |
| Built-in app templates | Different across layers | Repository | Use the effective runtime set: `alacritty`, `btop`, `gtk3`, `gtk4`, `kcolorscheme`, `qt`; leave `kitty` disabled |
| Enabled plugin list | Runtime only | Noctalia runtime | Preserve; do not write it from the design repo until plugin deployment is explicitly designed |
| Active/last wallpaper | Runtime only | Wallpaper studio state | Preserve until a committed profile transaction replaces it |
| Calendar, location, accounts | Runtime only and sensitive | Local runtime/secret service | Never print, import, snapshot broadly, or commit |
| Desktop/lock-screen placement | Runtime only and monitor-specific | Machine-local runtime | Keep out of shared config until per-monitor templating exists |
| Generated app theme files | Noctalia outputs | Generator | Snapshot for rollback; do not make generated copies source-of-truth |

## Font dependency decision

The design calls for Rubik as the UI/display face and Caskaydia Cove Nerd Font
for technical labels. Neither family currently resolves exactly on the host;
Fontconfig falls back to Noto Sans. Do not treat that fallback as visual
acceptance.

Before live preview, choose one of these reviewed paths:

1. Declare and install redistributable Rubik and Caskaydia packages when package
   operations are safe.
2. Change the tokens to already-installed Cantarell plus MesloLGS Nerd Font and
   re-review the screenshots.

The repo-only config may continue to name Rubik because its purpose is to
express the intended design and it is not deployed.

## Guarded reconciliation sequence

When live changes are allowed:

1. Confirm the LLM/protected workload can tolerate a shell hot reload.
2. Run `task desktop:audit` and `task desktop:noctalia:reconcile`.
3. Take a fresh `task desktop:snapshot` and record its ID.
4. Export the merged Noctalia configuration into a temporary private file for
   review; never add the raw export to Git.
5. Build a staged authored directory from reviewed repo fragments plus
   machine-local values.
6. Validate that directory with `noctalia config validate` under isolated XDG
   directories.
7. Show the exact authored and runtime keys that will change.
8. Remove only the approved duplicate runtime keys and install the authored
   files as one guarded transaction.
9. Allow one supported reload, verify shell IPC and the Llama widget, and roll
   back if either fails.

No step may terminate Noctalia/Hyprland, mutate a user service, log out, reboot,
or call a Llama operational command.
