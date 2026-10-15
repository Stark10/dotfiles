# Quiet Core Noctalia prototype

This directory is a repo-only, non-operational visual study for the Quiet Core
dashboard. It is not deployed by chezmoi, referenced by live Noctalia config,
or included in Hyprland autostart.

The prototype tests four design decisions:

- a full-available dashboard with clear Overview, Wallpaper, and System modes;
- restrained, role-based translucent surfaces instead of stacked blur;
- wallpaper browsing separated from theme commit;
- a hard ownership boundary between visual composition and the existing
  operational `samh/llama-control` plugin.

The Luau files contain no process execution, service calls, network access,
filesystem writes, wallpaper changes, or theme application. The wallpaper and
system pages deliberately use inert controls and designed empty states.

Do not copy this directory into the live plugin path while a protected workload
is active. A later preview must use the process and state-isolation procedure
defined by ADR 0001 and must take a fresh snapshot first.

Reference API snapshot: Noctalia official plugins commit
`52f6ef9f47f51aae72bdea743aed80abd525b943`.

Validation uses Noctalia's offline plugin linter under a temporary HOME,
temporary XDG directories, and an in-memory settings backend. It does not send
IPC to a running shell.
