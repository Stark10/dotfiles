# ADR 0001: implement Quiet Core on Noctalia v5

Status: proposed; selected for repo-first prototyping, pending live acceptance
Date: 2026-09-03
Decision owner: repository maintainer

## Context

Quiet Core uses Caelestia as its primary visual reference, but the target host
already runs Noctalia v5 and has a custom operational panel for a long-running
local LLM service. The implementation shell must support the desired quiet bar,
an immersive dashboard, wallpaper-led palettes, application theme propagation,
and recovery without making the desktop or LLM workload fragile.

The current protected-workload constraint prohibits logging out, rebooting,
restarting Hyprland or a layer shell, changing user services, signalling desktop
processes, installing shell packages, or applying live configuration. This
decision is therefore based on static feasibility evidence. It is not final
visual or performance acceptance.

## Decision

Use the installed Noctalia v5 shell as the implementation base for Quiet Core
version one. Use Caelestia as the visual and interaction specification rather
than installing or forking it as the active shell.

Build the distinct Quiet Core dashboard as a local Noctalia plugin, keep the
existing `samh/llama-control` plugin as a separately owned operational
component, and use Noctalia's native wallpaper, palette, template, launcher,
control-centre, notification, OSD, and lock-screen facilities wherever they
meet the design. Prefer configuration over custom code. A custom component
must have a concrete acceptance criterion and an owner.

This is a provisional implementation decision. It becomes accepted only after
the isolated configuration validates and a later live preview passes the gates
in this document.

## Evidence

### Existing Noctalia investment

- The host has Noctalia `v5.0.0_beta.10-1-dirty`; Caelestia and Quickshell are
  not installed.
- Hyprland autostart and shell keybinds already target the `noctalia` CLI.
- Authored Noctalia TOML and GUI/runtime overrides already exist, along with
  generated Alacritty, btop, GTK 3, and GTK 4 themes.
- `samh/llama-control` is not a generic command tile. Its API-24 Luau service,
  bar widget, and interactive panel share sampled state, render graphs, use
  Noctalia IPC, and expose guarded operational controls. Moving shells would
  require a UI rewrite and new lifecycle/error handling.

Noctalia's documented plugin surface supports services, widgets, panels,
desktop widgets, shared state, IPC, and declarative controls. A floating panel
can request `"fill"` on each axis, which is sufficient to prototype an
immersive dashboard without patching shell source. The plugin API is still
beta, so its version must be pinned and validated during updates.

Noctalia also distinguishes repository-authored config from GUI overrides and
provides wallpaper-derived palettes plus generated application templates. That
matches the ownership model and theme transaction described in the design.

References:

- <https://docs.noctalia.dev/noctalia/configuration/>
- <https://docs.noctalia.dev/noctalia/plugins/development/>
- <https://docs.noctalia.dev/noctalia/plugins/development/declarative-ui/>
- <https://docs.noctalia.dev/noctalia/theming/>
- <https://docs.noctalia.dev/noctalia/theming/app-theming/>

### Caelestia feasibility

Caelestia remains the closest visual match. Its current shell provides the
morphing edge treatment, dashboard composition, wallpaper launcher, dynamic
schemes, per-monitor configuration, and advanced spacing/shape/motion tokens
that informed Quiet Core.

The static review used upstream commit
`750e67d93ac12b264cb8cbc3a1f2b8f429c923c2` from 2026-09-02. At that commit:

- manual installation requires `quickshell-git`, the Caelestia CLI, a compiled
  QML plugin, and a substantial multimedia/system dependency set;
- the dashboard's Dashboard, Media, Performance, and Weather tabs are declared
  directly in `modules/dashboard/Content.qml`;
- the Nexus Plugins page is a placeholder and reports zero loaded plugins;
- the documented answer for an unsupported feature is an upstream feature
  request or source modification.

Consequently, integrating the current LLM control into Caelestia would most
likely mean maintaining a QML/source patch or a parallel standalone surface.
That is viable, but it carries a larger initial and update burden than a
Noctalia plugin and does not improve the wallpaper/theme requirement enough to
justify the migration in version one.

Reference: <https://github.com/caelestia-dots/shell>

## Consequences

Positive:

- The active shell, Hyprland bindings, generated app themes, and LLM panel can
  be retained.
- Most work can be developed as authored TOML, templates, and isolated plugin
  files before any live apply.
- Wallpaper and theme selection can use one native state model instead of a
  cross-shell bridge.
- Rollback remains narrow because there is no shell package or autostart
  migration in version one.

Negative:

- Caelestia's exact morphing geometry will be interpreted, not reproduced.
- A new dashboard panel and quiet bar treatment still require design and
  implementation work.
- The installed Noctalia build and plugin API are beta and need a compatibility
  pin plus upgrade tests.
- GUI overrides can shadow authored TOML until reconciliation is implemented.

## Explicitly rejected for version one

- Installing the full Caelestia dotfiles.
- Running Noctalia and Caelestia as simultaneous production shells.
- Copying Caelestia source or assets into this repository.
- Using Donburi's process-killing, service-switching, symlink replacement, or
  forced-logout workflow. Only its clear per-rice ownership boundary is used as
  a design reference.
- Replacing live configuration while the protected LLM workload is active.

## Acceptance gates

Before changing this ADR to `accepted`:

- [x] Produce a redacted Noctalia ownership report without committing transient
      state or secrets.
- [ ] Export and reconcile the approved GUI overrides during a safe apply
      window.
- [x] Validate the repo-only prototype configuration against an isolated
      config/state root using the installed Noctalia version.
- [ ] Reconcile that prototype into production-authored configuration without
      importing GUI/runtime state.
- [x] Prototype the quiet bar and a non-operational dashboard panel in repo
      fixtures.
- [ ] Prove the existing LLM plugin remains separately usable and is never
      invoked by visual validation.
- [ ] Preview on the live display only after the protected workload can tolerate
      a shell reload; take a fresh snapshot first.
- [ ] Compare quiet-desktop and dashboard screenshots against the design
      checklist.
- [ ] Record idle memory, GPU activity, animation behaviour, and recovery from
      invalid config.
- [ ] Confirm wallpaper preview/cancel does not rewrite application themes and
      commit applies them once.

## Reconsideration triggers

Re-open the decision if any of these occur:

- Noctalia cannot reproduce the required quiet bar or dashboard hierarchy
  without an invasive upstream fork.
- Plugin API churn makes the local dashboard or LLM control unreliable.
- Live performance exceeds the budgets established during the baseline.
- Caelestia gains a stable extension mechanism that can host the operational
  panel without source patches.
- Exact Caelestia fidelity becomes more important than retaining the current
  shell integration.
