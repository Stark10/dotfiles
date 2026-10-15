-- Quiet Core Hyprland appearance prototype.
--
-- This module is not required by the live Hyprland configuration. It is staged
-- here for review and offline syntax checks only.

local quietPrimary = "rgba(a7d96eff)"
local quietSecondary = "rgba(71c5b8ff)"
local quietOutline = "rgba(a6b0ab66)"

hl.config({
  general = {
    gaps_in = 4,
    gaps_out = 8,
    border_size = 1,
    extend_border_grab_area = 10,
    resize_on_border = true,
    col = {
      active_border = {
        colors = { quietPrimary, quietSecondary },
        angle = 45,
      },
      inactive_border = quietOutline,
    },
  },
  decoration = {
    rounding = 12,
    rounding_power = 3.0,
    active_opacity = 1.0,
    inactive_opacity = 1.0,
    fullscreen_opacity = 1.0,
    dim_special = 0.18,
    blur = {
      enabled = true,
      size = 6,
      passes = 2,
      ignore_opacity = true,
      new_optimizations = true,
      xray = false,
      noise = 0.008,
      contrast = 0.92,
      brightness = 0.96,
      vibrancy = 0.08,
      vibrancy_darkness = 0.0,
      special = false,
      popups = false,
    },
  },
})

hl.curve("quietOutQuint", {
  type = "bezier",
  points = { { 0.22, 1.0 }, { 0.36, 1.0 } },
})

hl.curve("quietOutCubic", {
  type = "bezier",
  points = { { 0.33, 1.0 }, { 0.68, 1.0 } },
})

-- Hyprland animation speed is measured in deciseconds.
hl.animation({ leaf = "global", enabled = true, speed = 2.5, bezier = "quietOutCubic" })
hl.animation({ leaf = "windows", enabled = true, speed = 2.5, bezier = "quietOutQuint", style = "popin 98%" })
hl.animation({ leaf = "layers", enabled = true, speed = 2.5, bezier = "quietOutQuint", style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3.6, bezier = "quietOutQuint", style = "slidefade 12%" })
hl.animation({ leaf = "specialWorkspaceIn", enabled = true, speed = 2.5, bezier = "quietOutQuint", style = "slide top" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 2.0, bezier = "quietOutCubic", style = "slide bottom" })
