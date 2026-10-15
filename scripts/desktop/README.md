# Desktop tooling

These scripts prepare and protect the Hyprland desktop work described in
[`docs/hyprland-desktop-design.md`](../../docs/hyprland-desktop-design.md).

They do not install a shell, change the login session, or switch the active
rice. In particular, they do not reproduce Donburi's process-kill and logout
steps. Those actions are intentionally excluded from the safety foundation.

## Commands

```bash
task desktop:audit
task desktop:noctalia:reconcile
task desktop:performance
task desktop:preview:dry-run
task desktop:preview
task desktop:preview:rollback:dry-run
task desktop:preview:rollback
task desktop:snapshot:dry-run
task desktop:snapshot
task desktop:rollback:dry-run
task desktop:prototype:validate
task desktop:themes:validate
```

- `audit.sh` reports redacted configuration and capability information. It
  prints exact process names and counts, never command lines.
- `noctalia-reconcile.sh` compares an allowlist of stable authored and runtime
  settings by ownership state without printing values or inspecting sensitive
  namespaces.
- `snapshot.sh` copies only the allowlisted desktop configuration paths to a
  private directory under `${XDG_STATE_HOME:-~/.local/state}`. It does not
  touch running processes.
- `rollback.sh` restores an allowlisted snapshot. It creates a pre-rollback
  snapshot and moves replaced files into that recovery snapshot rather than
  deleting them.
- `validate.sh` checks the safety scripts, performs a complete snapshot and
  rollback round trip in a temporary HOME, validates the Quiet Core design
  contracts, and—when installed—runs Noctalia's config validator and offline
  plugin linter in an isolated environment.
- `validate_profiles.py` validates the versioned tokens and Calm, Vivid, and
  Mono wallpaper-theme profiles without reading live configuration.
- `performance.sh` performs one read-only measurement of aggregate load,
  memory, GPU busy percentage, and desktop-process RSS. It never prints process
  IDs or arguments and does not poll.
- `preview.sh` performs the first guarded Noctalia-only preview. It refuses an
  active Llama request (and fails closed if activity cannot be verified),
  snapshots first, deploys atomically, removes only the runtime bar overrides
  that mask the candidate, checks IPC and plugin health, opens the dashboard,
  and automatically rolls back on failure.
- `preview-rollback.sh` restores the snapshot recorded for the active preview
  and requests a supported Noctalia config reload without restarting it.

Rollback can cause a running shell to hot-reload watched configuration files.
It therefore requires confirmation and should not be run during protected
workloads. Neither rollback nor snapshot sends signals, restarts services,
logs out, or reboots.

## Snapshot scope

The allowlist lives in `lib.sh`. It currently covers authored Hyprland and
Noctalia configuration, Noctalia's GUI override file, the custom LLM-control
plugin, and known generated theme files. Add a path only when an implementation
step is expected to own or rewrite it.

Snapshots are local safety artifacts and must not be committed.

## Repo-only prototype

`desktop/prototypes/noctalia/quiet-core/` is an inert visual prototype. It is
not deployed through chezmoi and contains no process, service, network,
wallpaper, or theme mutation calls. `desktop/themes/` is the implementation's
versioned design input; it is safe to validate while a protected workload is
running.

`desktop/prototypes/noctalia/config.toml` is the matching shell configuration
study. No live config includes it. The optional reduced-motion overlay has an
`.example` suffix so Noctalia cannot accidentally merge it as active TOML.

`desktop/prototypes/hyprland/quiet-core.lua` is the corresponding compositor
appearance proposal. It is absent from the live module graph and is checked
only for Lua syntax. Its reduced-effects overlay also uses an `.example`
suffix.
