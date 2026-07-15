#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h}"
VERSION="${1:-0.1.0}"
APP_NAME="LEO-MACOS快捷键助手"
ASCII_NAME="LEO-MACOS-Shortcut-Assistant-v$VERSION"
APP_PATH="$ROOT_DIR/dist/$APP_NAME.app"
RELEASE_DIR="$ROOT_DIR/release"
STAGING_DIR="$RELEASE_DIR/dmg-staging"

cd "$ROOT_DIR"
./build-app.sh

rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR" "$STAGING_DIR"

ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$RELEASE_DIR/$ASCII_NAME.zip"
cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$RELEASE_DIR/$ASCII_NAME.dmg" >/dev/null
rm -rf "$STAGING_DIR"

(cd "$RELEASE_DIR" && shasum -a 256 "$ASCII_NAME.zip" "$ASCII_NAME.dmg" > SHA256SUMS.txt)
ls -lh "$RELEASE_DIR"
