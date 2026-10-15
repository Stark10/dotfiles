# Hyprland desktop design and delivery plan

Status: in progress
Working title: **Quiet Core**
Last updated: 2026-09-03
Target host: CachyOS, Hyprland, 2560x1440 primary display
Repository: `Stark10/dotfiles`

## 1. Purpose

This document is the source of truth for refreshing the Hyprland desktop. It
defines the desired experience, design tokens, component behaviour, technical
boundaries, repository structure, delivery stages, validation, and unresolved
decisions.

The target is a calm, highly coherent desktop inspired primarily by Caelestia
Shell. The wallpaper and theme-selection experience borrows the theatrical
carousel interaction seen in Serpantinum and related wallpaper pickers. The
result should feel designed as one system without becoming a direct copy of
any reference.

This document deliberately separates two decisions:

1. **What the desktop should look and feel like.** This document makes that
   decision.
2. **Which shell should render it.** A static feasibility spike provisionally
   selected the installed Noctalia v5 shell for version one, with Caelestia
   retained as the visual specification. Live visual and performance
   acceptance remains gated by ADR 0001.

No implementation phase should silently expand the scope or replace the
working desktop. Each stage must be previewable and reversible.

## 2. Reference hierarchy

References are inspiration and implementation research, not dependencies by
default.

1. **Primary visual reference — Caelestia Shell**
   - Clean composition, large negative space, typography, edge-integrated
     chrome, dashboard structure, and restrained use of colour.
   - <https://github.com/caelestia-dots/shell>
   - <https://www.youtube.com/watch?v=Na7tPZv2ckk>
2. **Wallpaper interaction — Serpantinum**
   - Dramatic browsing, clear selection, wallpaper-led palette changes.
   - <https://github.com/ilyamiro/serpantinum>
3. **Carousel implementation reference — Wallpaper Carousel**
   - Fullscreen skewed carousel, keyboard navigation, Noctalia v5 integration.
   - <https://github.com/motor-dev/wallpaperCarousel>
4. **Rice-isolation reference — Donburi Rice Switcher**
   - Useful model for keeping complete shell configurations in separate slots
     with explicit ownership boundaries.
   - Its process termination, service switching, symlink replacement, and
     logout flow are not suitable for this project. No Donburi code is run.
   - <https://github.com/bgibson72/donburi-rice-switcher>
5. **Atmosphere reference — glassy CachyOS/Hyprland setup**
   - Smoked surfaces, low-saturation chrome, fine borders, and wallpaper light
     passing through selected overlays.
   - <https://www.youtube.com/watch?v=eo9MejbzWto>

When references disagree, prefer Caelestia's restraint. Glass is an effect,
not the organizing idea.

## 3. Product statement

> A quiet desktop that disappears during work, becomes an elegant dashboard
> on demand, and turns wallpaper and palette selection into its one cinematic
> interaction.

The experience has three intensity levels:

1. **Quiet desktop** — minimal persistent chrome and no decorative clutter.
2. **Focused surface** — launcher, control centre, notification, or OSD; one
   task at a time.
3. **Immersive surface** — dashboard, wallpaper browser, or session screen;
   full composition and richer motion.

## 4. Goals

- Make the normal desktop visually quieter than the current configuration.
- Establish a consistent system for spacing, shape, colour, type, and motion.
- Keep the wallpaper visually important without allowing extracted colours to
  make every surface bright or muddy.
- Provide one keyboard-first wallpaper and theme workflow with safe preview,
  commit, and cancel semantics.
- Preserve the current custom LLM control and useful GPU/temperature telemetry.
- Propagate a committed theme to the shell, Hyprland, GTK, Qt/KDE, terminals,
  btop, Zen Browser, and the lock/greeter where supported.
- Store authored configuration and scripts in this repository.
- Make installation, preview, rollback, and validation repeatable.
- Keep performance predictable during gaming, fullscreen video, and local LLM
  workloads.

## 5. Non-goals for the first release

- Recreating every Caelestia feature or animation.
- Replacing Hyprland or changing the distribution.
- Supporting a full light theme. Dark mode is the version-one target.
- Committing generated caches, GUI state, secrets, personal calendar data, or
  machine-specific monitor state.
- Applying transparency to every application window.
- Building a general-purpose theming framework for arbitrary Linux desktops.
- Shipping a public dotfile installer before the single-host experience is
  stable.

## 6. Current-state inventory

Observed on 2026-09-03:

- CachyOS with Hyprland configured in Lua under `~/.config/hypr/`.
- Noctalia `v5.0.0_beta.10-1-dirty` is the active shell.
- Noctalia authored configuration is in `~/.config/noctalia/config.toml`.
- Noctalia GUI/runtime overrides are in
  `~/.local/state/noctalia/settings.toml` and currently override some authored
  theme values.
- Wallpaper-derived theming is enabled with the `vibrant` scheme.
- Generated templates cover GTK 3/4, Qt/KDE, Alacritty, btop, and Zen Browser;
  Kitty is present in authored config but absent from the current runtime
  override list.
- The active wallpaper is `03-mossy-torii-stairs.jpg` from the local
  `Solarpunk-Shrines` collection.
- Hyprland currently uses 10 px rounding, 2 px borders, 3/8 px inner/outer
  gaps, 95% active opacity, 85% inactive opacity, and blur size 5 with 4
  passes.
- The Noctalia bar is 35 px tall, full-width, attached to the top edge, and
  uses several strong capsule fills.
- A custom `samh/llama-control` Noctalia plugin is installed outside this
  repository.
- The repository already uses chezmoi for home configuration and has Linux
  package/bootstrap support, but does not yet own Hyprland or Noctalia files.

Before implementation, refresh this inventory with a read-only script. Do not
assume the values above remain current.

## 7. Experience principles

### 7.1 Wallpaper is the scene; the shell is the instrument

Most pixels should belong to the wallpaper or application content. Persistent
shell surfaces should be small, neutral, and legible.

### 7.2 Colour communicates state

Wallpaper-derived colour is reserved for:

- the active workspace;
- focused or selected items;
- enabled toggles;
- progress and slider fill;
- the primary action;
- small status accents.

Inactive chrome uses neutral surface and text roles. Do not colour every
capsule, card, or icon from the wallpaper.

### 7.3 One dominant surface

Only one large shell surface should demand attention at a time. Opening the
dashboard, wallpaper browser, launcher, or session panel closes or visually
subordinates competing shell surfaces.

### 7.4 Progressive disclosure

The bar exposes state; panels expose controls; full views expose management.
For example, the bar shows GPU activity, a tooltip shows a summary, and the
dashboard provides graphs and detailed controls.

### 7.5 Motion explains change

Animation should establish origin, hierarchy, selection, and completion. It
must not delay keyboard use or exist only as decoration.

### 7.6 Preview must be reversible

Browsing wallpapers and palettes may temporarily alter the shell, but Escape
must restore the exact previous wallpaper and theme. Application theme files
are generated only when the user commits.

## 8. Visual system

### 8.1 Spatial scale

Use a 4 px base grid.

| Token | Value | Typical use |
| --- | ---: | --- |
| `space-1` | 4 px | icon/label micro-gap |
| `space-2` | 8 px | compact controls |
| `space-3` | 12 px | list rows and small cards |
| `space-4` | 16 px | standard card padding |
| `space-5` | 24 px | panel sections |
| `space-6` | 32 px | major regions |
| `space-8` | 48 px | immersive-layout separation |

Avoid arbitrary spacing values unless alignment or a platform constraint
requires one.

### 8.2 Shape scale

| Token | Value | Typical use |
| --- | ---: | --- |
| `radius-control` | 8 px | buttons, inputs, OSD |
| `radius-card` | 12 px | lists and compact cards |
| `radius-panel` | 18 px | launcher and attached panels |
| `radius-hero` | 24 px | dashboard and immersive cards |
| `radius-pill` | 999 px | workspace and slider indicators only |

Pills should communicate a continuous value, selection, or compact action.
They are not the default container shape.

### 8.3 Surface hierarchy

The percentages below are visual targets and may require tuning against the
actual compositor blur implementation.

| Surface | Fill target | Blur target | Border |
| --- | ---: | ---: | --- |
| Bar/edge chrome | 50–62% | 12–18 px perceived | none or 1 px at 6% |
| Tooltip/OSD | 78–86% | 12–18 px perceived | 1 px at 8% |
| Standard panel | 86–92% | 16–24 px perceived | 1 px at 8% |
| Dashboard backdrop | 70–82% scrim | 20–30 px perceived | none |
| Modal/auth surface | 92–96% | optional | 1 px at 10% |

Rules:

- Use one blurred layer plus opaque/translucent child cards; avoid stacking
  multiple blurred translucent cards.
- Shadows are broad and quiet: low opacity, 16–32 px blur, minimal offset.
- Use an inner highlight only where it materially clarifies a glass edge.
- Normal application windows remain opaque. Terminal transparency is optional
  and should stay above 90%.

### 8.4 Colour architecture

Separate stable neutral surfaces from the dynamic wallpaper palette.

Stable dark roles:

| Role | Starting value | Purpose |
| --- | --- | --- |
| `base` | `#090C0C` | desktop shell foundation |
| `surface` | `#111616` | primary cards |
| `surface-raised` | `#181E1D` | selected/raised cards |
| `text` | `#EDF2EF` | primary text |
| `text-muted` | `#A6B0AB` | secondary text |
| `outline` | white at 8–12% | separation |
| `shadow` | black at 30–45% | depth |

Dynamic roles derived from the active wallpaper:

| Role | Use |
| --- | --- |
| `primary` | selection, active workspace, main action |
| `secondary` | secondary data series and low-frequency accent |
| `tertiary` | rare emphasis or artwork complement |
| `error` | destructive actions; must not be wallpaper-derived |

The current mossy shrine wallpaper suggests a useful reference palette:

- primary moss: `#A7D96E`;
- secondary water/teal: `#71C5B8`;
- optional torii accent: `#E45B3E`;
- foreground: `#EDF4ED`;
- tinted glass: `#08100D`.

These are examples, not hard-coded output for every wallpaper.

### 8.5 Typography

Use at most two families in the active shell:

- **UI and display:** Rubik or another freely distributable rounded sans with
  strong numerals.
- **Telemetry and technical labels:** Caskaydia Cove Nerd Font or the existing
  Nerd Font baseline.

The Caelestia reference uses Google Sans Flex for much of its hierarchy. Do
not make redistribution of a restricted font a project dependency; reproduce
the typographic character with an approved alternative if needed.

| Style | Size | Weight | Use |
| --- | ---: | ---: | --- |
| Display | 64–96 px | 500 | lock/dashboard time |
| Heading | 24–32 px | 500 | immersive view heading |
| Title | 16–20 px | 500–600 | cards and panel titles |
| Body | 13–14 px | 400 | normal content |
| Label | 11–12 px | 500 | compact controls |
| Telemetry | 11–13 px | 400–500 | GPU, RAM, network |

Avoid ultra-light text over translucent surfaces.

### 8.6 Iconography

- Use one outline icon family with a consistent optical size.
- Default icons are monochrome.
- Colour is an active-state treatment, not an icon-category treatment.
- Standard size is 18 px; compact bar icons may be 16 px; hero actions may be
  22–24 px.
- Prefer recognizable symbols over text labels in the persistent bar, but
  always supply tooltips and accessible labels.

### 8.7 Motion tokens

| Token | Duration | Use |
| --- | ---: | --- |
| `motion-instant` | 90–120 ms | press feedback |
| `motion-fast` | 140–180 ms | hover, toggle, OSD |
| `motion-panel` | 220–280 ms | panel entrance/exit |
| `motion-hero` | 320–420 ms | dashboard and carousel |
| `motion-wallpaper` | 450–650 ms | committed wallpaper transition |

Use decelerating cubic or quint easing for arrival and a slightly faster exit.
An immersive surface may scale from 0.98 to 1.00 while fading. Avoid bounce.

Reduced-motion mode disables scale, deformation, parallax, and complex
wallpaper wipes while retaining short opacity transitions.

## 9. Component specification

### 9.1 Persistent bar

Purpose: show orientation and essential state without becoming a dashboard.

Preferred layout:

```text
  ● ━ ●   workspace/app                 14:32              media   GPU  RAM  net  audio
```

Specification:

- Top edge, 30–34 px high.
- One quiet continuous rail is preferred over many disconnected capsules.
- Background may become more opaque over bright wallpaper regions.
- Left: launcher affordance, workspaces, optional active application.
- Centre: time only. Date belongs in the dashboard or clock interaction.
- Right: compact media state, system group, notifications, network, audio,
  and session/control-centre entry.
- The custom LLM control belongs in the right system group. Its resting state
  is an icon plus concise status; model and memory detail move to its panel.
- Active workspace is a short accent lozenge. Inactive workspaces are dim dots.
- Avoid a filled capsule behind every item.
- Target maximum persistent labels: one active app label and one active media
  title. Hide media when idle.

### 9.2 Dashboard

Purpose: provide a composed summary and entry point to detailed controls.

Desktop-scale structure:

```text
┌───────────────┬─────────────────────┬──────────────────────┐
│ Weather       │       14:32         │ Performance          │
├───────────────┤     Thursday 3      ├──────────────────────┤
│ System        │                     │ Notifications        │
│ CPU · GPU     │  identity/artwork   │                      │
├───────────────┤                     │                      │
│ Media         │   search/actions    │                      │
└───────────────┴─────────────────────┴──────────────────────┘
```

- Centred and bounded; do not fill the entire monitor with opaque colour.
- Use three regions on landscape monitors and collapse to two or one on
  narrower displays.
- The centre establishes hierarchy with large time, date, optional avatar or
  artwork, and the universal search/action entry.
- Left contains glanceable weather, system identity, and media.
- Right contains performance and notifications.
- Empty states remain visually intentional; do not fill them with decorative
  charts solely to occupy space.
- Detailed audio, network, performance, calendar, and session controls open
  from the dashboard without creating overlapping panels.

### 9.3 Launcher and command surface

- Opens centred at 620–720 px wide.
- Input receives focus immediately and responds before entrance animation
  completes.
- Default results show icon, title, and one subdued metadata line.
- Search applications, calculations, actions, clipboard, windows, wallpaper,
  and session commands.
- Preserve provider prefixes but display them as understandable modes.
- Use a list for mixed results and an optional grid for applications only.
- Recent/frequent applications may appear before typing but should not create
  a permanent dock requirement.

### 9.4 Control centre

- Compact side rail plus one content region.
- Sections: Home, Media, Audio, Displays, System, Network, Bluetooth,
  Notifications, Calendar, Power/Session.
- Direct opens from bar controls land on the relevant section.
- Media artwork or a performance graph may be the expressive element; other
  controls stay compact.
- Use progressive disclosure rather than one screen of every available
  setting.

### 9.5 Wallpaper and theme studio

This is the signature interaction and may be entered from the dashboard,
launcher, bar action, or `Super+Shift+W`.

```text
 Dashboard       Wallpaper       Theme

       ╱ previous ╱    [ selected wallpaper ]    ╲ next ╲

  03 · Mossy Torii Stairs                    ● ● ● ● ●
  Mood:  Adaptive   Calm   Vivid   Mono   Preset

  Esc Cancel                         Space Preview   Enter Apply
```

#### Browse state

- Darken and gently blur the current desktop.
- Display a large central wallpaper with progressively smaller, dimmer,
  skewed neighbours.
- Pre-cache thumbnails; do not decode full-resolution images on every key
  press.
- Support arrows and `H/L`, pointer scrolling, click selection, and search.
- Show filename, dimensions, type, favourite state, and dominant swatches.
- Optional filters: folder, favourite, image/video, and dominant hue.

#### Theme state

Expose human names with an implementation mapping:

| UI label | Intent | Initial Noctalia mapping |
| --- | --- | --- |
| Adaptive | source-faithful daily palette | `faithful` or `m3-content` |
| Calm | lower-chroma daily palette | `soft` or `muted` |
| Vivid | saturated showcase palette | `vibrant` |
| Mono | single-hue minimal palette | `m3-monochrome` |
| Preset | curated non-wallpaper palette | built-in/community/custom |

The feasibility spike must compare these mappings on bright green, dark blue,
warm orange, monochrome, and skin-tone-heavy wallpapers.

#### Transaction semantics

1. Opening records the current wallpaper, colour source, scheme, and mode.
2. Navigation updates the large preview only.
3. Explicit preview updates shell colours and wallpaper temporarily.
4. Preview does **not** render all application templates.
5. Apply persists wallpaper and scheme, then renders configured templates.
6. If application fails, restore the last known-good profile and report which
   target failed.
7. Escape restores the recorded state exactly.

The implementation must prevent overlapping theme jobs. A later selection
cancels or supersedes an earlier preview.

### 9.6 Notifications

- Position below the bar at the top right.
- 320–380 px wide depending on UI scale.
- Maximum three visible; queue additional notifications.
- App identity is conveyed by the icon and, optionally, a 2 px accent—not by
  colouring the full card.
- Duplicate notifications group when supported.
- Critical notifications may use the stable error role and remain visible
  longer.
- Motion uses a short lateral/vertical arrival and opacity; remaining cards
  close gaps smoothly.

### 9.7 OSD

- Bottom-centre compact surface.
- Icon, value bar, and optional percentage only.
- Repeated key presses update the existing OSD instead of spawning new ones.
- Hold for roughly 700–900 ms after the final change, then fade.
- Microphone mute and dangerous thermal/battery state must be distinguishable
  without relying on colour alone.

### 9.8 Lock screen and greeter

- Use the active wallpaper with a stronger dim/blur treatment.
- Large time, compact date, and one password capsule.
- Weather and media may appear only when they do not compete with unlock.
- Session buttons are visually secondary and require confirmation for
  destructive actions.
- Reveal wallpaper first and controls second on wake.
- Greeter synchronization is a later milestone; the lock screen must work
  independently.

### 9.9 Hyprland windows

- Normal tiled windows: 100% opacity.
- Optional terminal/editor glass: 90–94% opacity.
- Active border: 1 px dynamic primary at roughly 60–75% visual strength.
- Inactive border: 1 px neutral at roughly 12–20%.
- Rounding: 8–10 px.
- Gaps: start with 6 px inner and 10 px outer, then tune on the real display.
- Shadows: restrained and disabled for fullscreen/gaming where appropriate.
- Blur only shell surfaces and explicitly opted-in application surfaces.
- Fullscreen gaming bypasses blur, borders, rounding, and shell overlay where
  practical.

### 9.10 Custom LLM and performance controls

- Preserve current start/stop/status behaviour.
- Bar state: small icon, running/idle/error indication, optional memory value.
- Detail surface: loaded model, context, process status, memory usage, power
  cap, start/stop controls, and a link/command for logs.
- Destructive stop/restart actions need clear labels and immediate feedback.
- The plugin should consume design tokens rather than define its own palette.

## 10. Theme pipeline

Desired committed flow:

```text
Wallpaper selection
        │
        ├── extract/resolve palette
        │       ├── stable neutral surfaces
        │       └── dynamic primary/secondary/tertiary
        │
        ├── persist profile atomically
        ├── update wallpaper with transition
        ├── update shell colours
        ├── generate application theme files
        ├── generate Hyprland colour include
        ├── reload supported applications/services
        └── record last-known-good state
```

Prefer the selected shell's native wallpaper and palette pipeline. Add an
orchestration script only for missing guarantees such as transactional apply,
cross-application reload, or rollback.

Authored theme profiles use stable identifiers and contain no wallpaper paths.
The wallpaper studio combines one profile with a relative wallpaper selection
at preview/commit time. The versioned profile contract is:

```toml
schema = 1
id = "calm"
label = "Calm"
description = "Low-chroma wallpaper colours for focused daily work."
mode = "dark"
palette_source = "wallpaper"
wallpaper_scheme = "soft"

[surfaces]
contrast = "low"
accent_frequency = "active-only"

[motion]
intensity = "restrained"
```

`desktop/themes/profiles/` contains Calm, Vivid, and Mono. Machine-local
wallpaper roots and relative image selections belong in chezmoi data or local
configuration, not in shared profiles. `desktop/wallpapers.example.toml`
documents that boundary.

## 11. Shell implementation decision

The visual design does not require a shell replacement. A static feasibility
spike selected Noctalia for repo-first prototyping; live confirmation remains
deferred while the protected workload is active.

### Option A — extend Noctalia v5

Advantages:

- Already installed and running on the target host.
- Existing wallpaper-derived themes and application templates.
- Existing custom LLM control is a Noctalia v5 plugin.
- Native `glass` panel mode, wallpaper schemes, control centre, launcher,
  lock-screen widgets, and Hyprland integration.
- Current Wallpaper Carousel has an explicit Noctalia v5 path.

Risks:

- Exact Caelestia dashboard composition and edge morphing may require custom
  plugins or upstream changes.
- GUI state can override repository-authored TOML unless ownership is made
  explicit.
- The installed build is a beta/dirty package and must be version-pinned or
  tested carefully.

### Option B — use Caelestia as the primary shell

Advantages:

- Closest to the chosen design language by construction.
- Dashboard, edge chrome, typography, animation, launcher, wallpaper, and
  dynamic schemes already share one implementation.
- Configuration has explicit appearance, transparency, dashboard, launcher,
  wallpaper, and scheme controls.

Risks:

- Requires Quickshell git and a separate dependency set.
- Needs compatibility testing against this CachyOS installation.
- The custom LLM control must be ported or exposed through a generic command
  surface.
- Running two full shells simultaneously is not a supported end state.
- Update cadence and configuration compatibility need an ownership strategy.

### Spike deliverables

- Run both options without changing the default login session.
- Record startup time, idle RAM, GPU cost, blur/frame behaviour, and failure
  recovery.
- Prototype the persistent bar and one dashboard section in each option.
- Verify wallpaper preview and committed application theme propagation.
- Verify the LLM control can be preserved or ported.
- Produce a short decision record with recommendation and rejected option.

Decision rule: choose the smallest maintainable implementation that reproduces
the experience, not the one with the shortest initial demo.

## 12. Repository architecture

Proposed eventual layout:

```text
docs/
  hyprland-desktop-design.md       this source of truth
  decisions/
    0001-shell-selection.md        result of feasibility spike
desktop/
  prototypes/noctalia/quiet-core/  inert visual feasibility prototype
  themes/                          authored theme profiles and metadata
  wallpapers.example.toml         path/config example; no personal paths
home/
  private_dot_config/
    hypr/                          authored Hyprland Lua
    noctalia/                      if Noctalia is selected
    caelestia/                     if Caelestia is selected
scripts/
  desktop/
    audit.sh                       read-only dependency/config inventory
    preview.sh                     isolated preview session/profile
    apply.sh                       guarded chezmoi/theme application
    rollback.sh                    restore last-known-good state
    validate.sh                    static and behavioural checks
```

Only the selected shell directory should become active. Do not retain two
autostarting shell configurations.

### 12.1 Configuration ownership

Track:

- authored Hyprland modules;
- authored shell configuration;
- custom plugins we own or deliberately vendor;
- theme profiles and templates;
- dependency declarations;
- scripts and validation fixtures.

Do not track:

- `~/.local/state/noctalia/settings.toml` as-is;
- caches, thumbnails, logs, notification history, calendar tokens, or secrets;
- machine-generated monitor IDs without templating;
- downloaded community plugins without a pinned source/version strategy;
- copyrighted wallpaper collections unless redistribution is explicitly
  permitted.

For Noctalia, authored TOML and GUI-managed runtime state must not both own the
same stable setting. Stable settings should move into the repo; transient
state remains local. Provide an export/reconciliation command before taking
ownership.

### 12.2 Chezmoi integration

- Gate desktop files to Linux and, where necessary, CachyOS/Arch hosts.
- Keep monitor names, wallpaper root, user name, and hardware-specific commands
  in machine-local chezmoi data.
- Preview with `chezmoi diff` before every apply.
- Use templates only for actual host variation; avoid templating ordinary
  values.
- Never make the generic development bootstrap unexpectedly replace a user's
  desktop. Desktop installation requires an explicit flag or dedicated task.

## 13. Required scripts and tasks

Names may change after the shell decision, but responsibilities should remain.

### `scripts/desktop/audit.sh`

Read-only output:

- OS, compositor and shell versions;
- monitor connectors, modes, scale, and position;
- relevant packages and binaries;
- running shell processes and user units;
- authored and runtime config locations;
- wallpaper directory and active wallpaper;
- template/plugin inventory;
- potential ownership conflicts.

It must redact tokens, credentials, calendar details, network identifiers, and
other sensitive values.

### `scripts/desktop/preview.sh`

- Launch a disposable or alternate shell profile.
- Never change the default session or autostart.
- Use an isolated config/state directory where supported.
- Print the exact stop command.
- Refuse to start a second conflicting shell unless the selected preview mode
  is known to isolate its layer surfaces.

### `scripts/desktop/apply.sh`

- Require a clean validation result.
- Show the chezmoi diff.
- Snapshot only files it may change.
- Require explicit confirmation unless `--yes` is passed.
- Apply authored configuration.
- Validate shell configuration before restart/reload where supported.
- Reload gracefully and verify the new shell is responsive.
- Automatically call rollback if the health check fails.

### `scripts/desktop/rollback.sh`

- Restore the most recent script-created snapshot.
- Never delete unrelated user files.
- Print restored paths and whether a logout is required.
- Retain a bounded number of snapshots by an explicit, documented policy.

### `scripts/desktop/theme-apply.sh` if needed

- Validate the requested profile and wallpaper.
- Serialize theme jobs with a lock.
- Stage generated files before replacing live files.
- Apply the wallpaper and shell palette.
- Render application templates in a deterministic order.
- Reload only supported targets.
- Record success as last-known-good; rollback on partial failure.

### Repository tasks

Proposed Task targets:

```text
desktop:audit       Read-only host and configuration report
desktop:validate    Validate desktop scripts and authored configuration
desktop:preview     Start an isolated visual preview
desktop:diff        Show chezmoi changes for desktop-owned files
desktop:apply       Guarded apply with snapshot and health check
desktop:rollback    Restore the last script-created snapshot
```

## 14. Delivery plan

### Milestone 0 — baseline and safety

- [x] Implement the redacted read-only audit.
- [ ] Capture screenshots of quiet desktop, launcher, control centre,
      wallpaper picker, notification, OSD, lock screen, and fullscreen game.
- [x] Record current package versions and configuration ownership.
- [x] Establish and test targeted snapshot/rollback procedures.
- [x] Establish a guarded, snapshot-backed Noctalia preview that uses supported
      hot reload and does not start a second layer shell.
- [x] Define a single-read, redacted performance measurement command.
- [ ] Capture idle baseline values after unrelated GPU workloads finish.

Exit criteria: the current desktop can be restored without guesswork.

### Milestone 1 — shell feasibility spike

- [x] Stage the Noctalia v5 route as an inert repo-only visual prototype.
- [ ] Prototype Caelestia route without changing default autostart.
- [x] Verify the existing custom LLM control can remain separately owned on
      the Noctalia route without invoking it.
- [ ] Compare maintainability, performance, visual fidelity, and failure modes.
- [x] Write the proposed `docs/decisions/0001-shell-selection.md`.

Exit criteria: one shell route is explicitly selected and the other rejected
with reasons.

### Milestone 2 — foundations

- [ ] Bring selected authored configuration under chezmoi.
- [ ] Add Linux/host gating and local variables.
- [x] Define versioned spacing, shape, colour, typography, motion, and
      accessibility tokens.
- [x] Map the visual targets into an isolated Noctalia prototype config and
      validate it with the installed parser.
- [ ] Map accepted tokens into managed Noctalia and Hyprland configuration.
- [x] Stage a repo-only Hyprland 0.56 appearance module with opaque
      applications, lower-cost blur, restrained motion, and a reduced-effects
      overlay.
- [ ] Configure Hyprland window opacity, gaps, border, rounding, blur, and
      shell layer rules.
- [ ] Implement solid/reduced-motion fallbacks.

Exit criteria: bar, panels, launcher, and custom control visibly share one
design language.

### Milestone 3 — quiet desktop and dashboard

- [x] Prototype the simplified persistent bar in the guarded live preview.
- [x] Build and open the inert dashboard composition.
- [ ] Integrate media, weather, performance, notification, and LLM states.
- [ ] Define responsive layouts for primary and secondary monitors.
- [ ] Complete empty, loading, error, and offline states.

Exit criteria: daily shell use works without the wallpaper studio.

### Milestone 4 — wallpaper and theme studio

- [ ] Select, pin, or implement the carousel component.
- [ ] Add thumbnail caching and keyboard navigation.
- [ ] Add theme mood selection and palette swatches.
- [ ] Implement reversible preview.
- [ ] Implement atomic commit and application template rendering.
- [ ] Add last-known-good rollback.
- [ ] Test image collections with different luminance and hue distributions.

Exit criteria: wallpaper plus palette can be previewed, applied, cancelled, and
recovered entirely from the UI and keyboard.

### Milestone 5 — secondary surfaces

- [ ] Restyle notifications and history.
- [ ] Restyle volume, brightness, microphone, and keyboard OSDs.
- [ ] Complete lock screen.
- [ ] Evaluate greeter sync.
- [ ] Finish session/power confirmations.

Exit criteria: no default-looking shell surface remains in the normal flow.

### Milestone 6 — hardening and documentation

- [ ] Measure idle and animated performance.
- [ ] Verify fullscreen/gaming bypass behaviour.
- [ ] Test compositor/shell restart and failed theme generation.
- [ ] Test missing wallpaper, missing font, and missing optional service states.
- [ ] Add install, update, troubleshooting, and rollback documentation.
- [x] Add desktop checks to the repository's validation task.

Exit criteria: a clean-machine or new-user application can reproduce the
desktop through documented, guarded steps.

## 15. Acceptance criteria

### Visual

- Persistent chrome occupies no more space than required and does not dominate
  an empty desktop screenshot.
- Surface geometry uses the documented spacing and radius scale.
- Dynamic wallpaper colour is visibly concentrated in active state.
- Bright, dark, saturated, and monochrome wallpapers retain readable shell
  text and clear focus.
- Normal application content is not made translucent globally.

### Interaction

- Launcher accepts keyboard input immediately.
- Every common shell action is keyboard accessible.
- Wallpaper preview never permanently changes application themes.
- Escape restores the exact pre-preview wallpaper and palette.
- Apply produces a single coherent committed state.
- Repeated volume/brightness input updates one OSD.
- Failure states explain recovery without requiring a terminal where feasible.

### Reliability

- Desktop configuration validates before it replaces the live version.
- A failed shell reload or theme apply triggers a documented recovery path.
- The user can start a fallback session or disable the shell from a TTY.
- Bootstrap does not opt hosts into the desktop without an explicit action.
- Generated state and secrets are absent from Git.

### Performance

- No overlapping blur layers in the normal bar/panel path.
- Wallpaper browser uses thumbnails and remains responsive with the target
  wallpaper collection.
- Theme jobs are serialized and do not accumulate during rapid navigation.
- Fullscreen games do not retain unnecessary blur, shadow, or overlay cost.
- A solid, reduced-effects profile is available.

## 16. Validation strategy

Static checks:

- shell syntax checks for all scripts;
- TOML/JSON parsing for authored configuration and profiles;
- Lua validation for Hyprland modules where a suitable parser/runtime exists;
- detection of absolute personal paths outside approved templates;
- detection of secrets and generated state paths;
- executable permission checks for scripts;
- dependency and version reporting.

Behavioural checks:

- isolated config can launch and answer its IPC health command;
- opening and closing each shell surface leaves no orphan process;
- preview/cancel round-trip preserves initial wallpaper and palette;
- apply failure restores staged files;
- missing optional services produce designed empty states;
- shell restart preserves committed wallpaper/theme and plugin availability.

Visual checks:

- capture the same named surfaces at 2560x1440;
- compare bright and dark wallpaper fixtures;
- inspect text contrast, alignment, clipping, animation origin, and empty states;
- maintain a short manual review checklist rather than brittle pixel-perfect
  screenshot tests during early design work.

## 17. Safety and recovery

Before the first live apply:

- confirm a known-good TTY login;
- document the command that disables the selected shell autostart;
- retain the current Hyprland and Noctalia configs in a dated, script-created
  snapshot;
- preserve an alternative graphical session if already installed;
- validate the new config outside the live path where the shell supports it.

The initial private baseline is snapshot `20260903T040032Z`. It was created by
`scripts/desktop/snapshot.sh` without changing configuration or process state.
The rollback implementation passed an isolated round-trip test; it has not
been run against the live desktop.

The first guarded live preview is backed by snapshot `20260903T100701Z`. It
changed only the Noctalia authored config, the Noctalia runtime bar override,
the new local Quiet Core plugin, and the wallpaper-derived colour scheme.
No process, service, compositor, login session, or Hyprland file was restarted
or changed. `task desktop:preview:rollback` restores the recorded snapshot.

While long-running LLM work is active, all implementation remains repo-first.
Do not reboot, log out, restart Hyprland or a layer shell, mutate user services,
signal desktop processes, install/replace shell packages, or apply live theme
state. Passive audit and snapshot operations are allowed.

Scripts must resolve and print exact target paths before changing them. They
must not recursively delete configuration roots, reset the Git worktree, or
overwrite unrelated GUI state.

## 18. Decisions and open questions

### Decided

- [x] Caelestia is the primary visual reference.
- [x] Serpantinum/carousel designs inform wallpaper selection.
- [x] The normal desktop should be quieter than the immersive views.
- [x] Glass is a secondary depth treatment.
- [x] Dark mode is the version-one target.
- [x] Wallpaper preview and theme commit are separate operations.
- [x] Normal application windows remain opaque.
- [x] This dotfiles repository will own authored configuration and automation.

### To decide during the spike

- [x] Provisional Noctalia v5 implementation for version one; live acceptance
      remains gated by `docs/decisions/0001-shell-selection.md`.
- [ ] Continuous top rail or Caelestia-style edge/morphing bar.
- [ ] Dashboard avatar/artwork choice and whether it is shown by default.
- [ ] Exact UI font with acceptable redistribution terms.
- [ ] Wallpaper Carousel dependency, fork, or a smaller native implementation.
- [ ] Whether committed wallpapers are referenced locally or managed through a
      separate licensed asset repository.
- [ ] Whether theme profiles support per-monitor wallpapers in version one.
- [ ] Whether greeter synchronization is safe enough for version one.

## 19. Work log

Use this section for short milestone updates. Significant architectural choices
belong in `docs/decisions/` once implementation begins.

| Date | Update | Result |
| --- | --- | --- |
| 2026-09-03 | Initial reference and live-config review | Caelestia-led direction selected; implementation shell remains open |
| 2026-09-03 | Design and delivery plan created | Ready for baseline/safety milestone |
| 2026-09-03 | Added guarded desktop foundation commands | Audit, snapshot, rollback, isolated tests, and Task targets pass |
| 2026-09-03 | Captured private baseline `20260903T040032Z` | Eight allowlisted paths saved; no live config or process state changed |
| 2026-09-03 | Reviewed Donburi switching architecture | Retain the isolation concept; reject its disruptive switching flow |
| 2026-09-03 | Completed static shell feasibility review | Provisional Noctalia v5 route recorded in ADR 0001; live acceptance deferred |
| 2026-09-03 | Staged inert Quiet Core dashboard prototype | No I/O or operational APIs; file-based validation passes |
| 2026-09-03 | Added versioned tokens and Calm/Vivid/Mono profiles | TOML contracts and range/scheme validation pass |
| 2026-09-03 | Added isolated Noctalia config prototype | Installed parser reports valid; no live TOML changed |
| 2026-09-03 | Added Hyprland appearance and reduced-effects prototypes | Lua syntax passes; normal/fullscreen windows remain opaque |
| 2026-09-03 | Added redacted single-read performance snapshot | No polling/arguments; active GPU workload correctly invalidates idle baseline |
| 2026-09-03 | Documented Noctalia ownership and reconciliation | Effective app templates retained; sensitive/runtime scopes stay local |
| 2026-09-03 | Applied guarded Quiet Core preview `20260903T100701Z` | Bar, soft wallpaper palette, and inert dashboard are live; Noctalia and Llama were not restarted |

## 20. Immediate next actions

1. Review the live bar and the Overview, Wallpaper, and System dashboard pages;
   record concrete spacing, density, and composition feedback.
2. Capture the remaining baseline/preview surface set with a method that
   includes transient Noctalia panel layers.
3. Capture a true idle performance baseline only after the loaded GPU model can
   be stopped deliberately; zero active requests alone is not a desktop-idle
   baseline.
4. Choose the declared font dependency or approve the installed-font fallback.
5. Turn the inert Wallpaper page into a transactional wallpaper/theme studio
   after the visual composition is accepted.
