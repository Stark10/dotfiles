#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
elif (($#)); then
  echo "Usage: $0 [--dry-run]" >&2
  exit 2
fi

if [[ $(uname -s) != Linux ]]; then
  echo "LM Studio's AppImage installer is only supported on Linux." >&2
  exit 1
fi

case $(uname -m) in
  x86_64) ARCH=x64 ;;
  aarch64 | arm64) ARCH=arm64 ;;
  *)
    echo "Unsupported architecture: $(uname -m)" >&2
    exit 1
    ;;
esac

INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/lm-studio"
BIN_DIR="$HOME/.local/bin"
APPLICATIONS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
APPIMAGE="$INSTALL_DIR/LM-Studio.AppImage"
DOWNLOAD_URL="https://lmstudio.ai/download/latest/linux/$ARCH?format=AppImage"
DESKTOP_FILE="$APPLICATIONS_DIR/lm-studio.desktop"

if $DRY_RUN; then
  printf '[dry-run] install LM Studio from %s to %s\n' "$DOWNLOAD_URL" "$APPIMAGE"
  printf '[dry-run] link %s/lm-studio to the AppImage\n' "$BIN_DIR"
  printf '[dry-run] create desktop launcher at %s\n' "$DESKTOP_FILE"
  exit 0
fi

mkdir -p "$INSTALL_DIR" "$BIN_DIR" "$APPLICATIONS_DIR"
TEMP_APPIMAGE=$(mktemp "$INSTALL_DIR/.LM-Studio.AppImage.XXXXXX")
cleanup() {
  rm -f -- "$TEMP_APPIMAGE"
}
trap cleanup EXIT

curl --fail --location --proto '=https' --tlsv1.2 \
  --output "$TEMP_APPIMAGE" "$DOWNLOAD_URL"
chmod 755 "$TEMP_APPIMAGE"
mv -f -- "$TEMP_APPIMAGE" "$APPIMAGE"
ln -sfn -- "$APPIMAGE" "$BIN_DIR/lm-studio"

cat >"$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=LM Studio
Comment=Run local language models
Exec=$APPIMAGE %U
Terminal=false
Type=Application
Icon=lm-studio
Categories=Development;
StartupWMClass=LM Studio
MimeType=x-scheme-handler/lmstudio;
EOF

update-desktop-database "$APPLICATIONS_DIR" >/dev/null 2>&1 || true
echo "LM Studio installed. Launch it from the app menu or run: lm-studio"
