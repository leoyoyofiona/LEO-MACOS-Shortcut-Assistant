#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h}"
APP_NAME="LEO-MACOS快捷键助手"
BUILD_DIR="$ROOT_DIR/dist"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
LEGACY_APP_DIR="$BUILD_DIR/快捷助手.app"

cd "$ROOT_DIR"
swift build -c release

rm -rf "$APP_DIR" "$LEGACY_APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp ".build/release/ShortcutLens" "$APP_DIR/Contents/MacOS/ShortcutLens"
cp "Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"

SIGNING_IDENTITY="${SHORTCUTLENS_SIGNING_IDENTITY:-$(security find-identity -v -p codesigning | awk -F '"' '/Apple Development:/ { print $2; exit }')}"
if [[ -n "$SIGNING_IDENTITY" ]]; then
    codesign --force --deep --options runtime --identifier com.local.ShortcutLens --sign "$SIGNING_IDENTITY" "$APP_DIR"
    echo "Signed with: $SIGNING_IDENTITY"
else
    codesign --force --deep --identifier com.local.ShortcutLens --sign - "$APP_DIR"
    echo "Signed ad hoc (no Apple Development identity found)"
fi
echo "$APP_DIR"
