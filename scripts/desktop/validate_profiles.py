#!/usr/bin/env python3
"""Validate Quiet Core design tokens and wallpaper-theme profiles."""

from __future__ import annotations

import re
import sys
import tomllib
from pathlib import Path
from typing import Any


SUPPORTED_SCHEMES = {
    "m3-tonal-spot",
    "m3-content",
    "m3-fruit-salad",
    "m3-rainbow",
    "m3-monochrome",
    "vibrant",
    "faithful",
    "soft",
    "dysfunctional",
    "muted",
}


def load_toml(path: Path) -> dict[str, Any]:
    with path.open("rb") as source:
        return tomllib.load(source)


def require(condition: bool, message: str, errors: list[str]) -> None:
    if not condition:
        errors.append(message)


def validate_tokens(path: Path, errors: list[str]) -> None:
    data = load_toml(path)
    require(data.get("schema") == 1, f"{path}: schema must be 1", errors)

    spacing = data.get("spacing", {})
    expected_spacing = {
        "space_1": 4,
        "space_2": 8,
        "space_3": 12,
        "space_4": 16,
        "space_5": 24,
        "space_6": 32,
        "space_8": 48,
    }
    require(spacing == expected_spacing, f"{path}: spacing scale drifted", errors)

    shape = data.get("shape", {})
    for name in ("control", "card", "panel", "hero", "pill"):
        require(isinstance(shape.get(name), int), f"{path}: shape.{name} must be an integer", errors)

    surface = data.get("surface", {})
    for low_name, high_name in (
        ("bar_fill_min", "bar_fill_max"),
        ("osd_fill_min", "osd_fill_max"),
        ("panel_fill_min", "panel_fill_max"),
        ("dashboard_scrim_min", "dashboard_scrim_max"),
        ("modal_fill_min", "modal_fill_max"),
    ):
        low = surface.get(low_name)
        high = surface.get(high_name)
        require(
            isinstance(low, (int, float))
            and isinstance(high, (int, float))
            and 0 <= low <= high <= 1,
            f"{path}: invalid surface range {low_name}/{high_name}",
            errors,
        )

    colours = data.get("colour", {}).get("dark", {})
    for name in ("base", "surface", "surface_raised", "text", "text_muted"):
        require(
            isinstance(colours.get(name), str)
            and re.fullmatch(r"#[0-9A-Fa-f]{6}", colours[name]) is not None,
            f"{path}: colour.dark.{name} must be #RRGGBB",
            errors,
        )

    motion = data.get("motion", {})
    for name in ("instant_ms", "fast_ms", "panel_ms", "hero_ms", "wallpaper_ms"):
        value = motion.get(name)
        require(isinstance(value, int) and 50 <= value <= 1000, f"{path}: invalid motion.{name}", errors)


def validate_profiles(directory: Path, errors: list[str]) -> None:
    profiles = sorted(directory.glob("*.toml"))
    require(bool(profiles), f"{directory}: no profiles found", errors)
    seen: set[str] = set()

    for path in profiles:
        data = load_toml(path)
        profile_id = data.get("id")
        require(data.get("schema") == 1, f"{path}: schema must be 1", errors)
        require(profile_id == path.stem, f"{path}: id must match the filename", errors)
        require(isinstance(profile_id, str) and profile_id not in seen, f"{path}: duplicate id", errors)
        if isinstance(profile_id, str):
            seen.add(profile_id)
        require(data.get("mode") == "dark", f"{path}: version one supports dark mode only", errors)
        require(data.get("palette_source") == "wallpaper", f"{path}: palette must be wallpaper-derived", errors)
        require(
            data.get("wallpaper_scheme") in SUPPORTED_SCHEMES,
            f"{path}: unsupported wallpaper_scheme",
            errors,
        )
        require(data.get("surfaces", {}).get("contrast") in {"low", "medium", "high"}, f"{path}: invalid contrast", errors)
        require(
            data.get("motion", {}).get("intensity") in {"restrained", "expressive"},
            f"{path}: invalid motion intensity",
            errors,
        )


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: validate_profiles.py REPOSITORY_ROOT", file=sys.stderr)
        return 2

    repo_root = Path(sys.argv[1]).resolve()
    errors: list[str] = []
    validate_tokens(repo_root / "desktop/themes/tokens.toml", errors)
    validate_profiles(repo_root / "desktop/themes/profiles", errors)
    load_toml(repo_root / "desktop/wallpapers.example.toml")

    if errors:
        for error in errors:
            print(f"error: {error}", file=sys.stderr)
        return 1

    print("Quiet Core tokens and profiles are valid.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
