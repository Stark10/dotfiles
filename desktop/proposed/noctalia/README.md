# Proposed Noctalia configuration

This is the reviewed candidate for the first guarded live preview. It preserves
the current UI scale, application-launch integration, polkit agent, screenshot
workflow, session actions, GPU polling, application templates, and Llama widget.

The visual changes are limited to the Quiet Core bar, soft-glass panels, OSD,
wallpaper scheme, and widget styling. Greeter auto-sync is disabled so a shell
preview cannot propagate appearance changes into the login screen.

This directory is not managed by chezmoi and is not read by live Noctalia. Use
only `scripts/desktop/preview.sh`, which validates, snapshots, installs
atomically, checks IPC health, and records the exact rollback snapshot.
