# Quiet Core Hyprland prototype

`quiet-core.lua` is a repo-only appearance proposal for Hyprland 0.56. It is
not imported by the live `hyprland.lua` and no script applies it.

The proposal intentionally:

- keeps normal and fullscreen application windows fully opaque;
- reduces the existing blur from four passes to two and disables expensive
  special-workspace and popup blur;
- uses a one-pixel restrained border, 4/8px gaps, and 12px window rounding;
- replaces overshoot/spring motion with short cubic/quint transitions;
- provides a separate reduced-effects example that disables blur and motion.

The static moss/teal border colours are review fixtures. Production values
will come from a staged theme include after the atomic theme pipeline exists.
Do not add this file to the live module graph while a protected workload is
active.
