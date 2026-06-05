#!/bin/sh
set -eu

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
VERSION="${VERSION:-0.1.0}"
APP_NAME="PulseDock"
APP_PATH="$ROOT_DIR/.build/$APP_NAME.app"
DIST_DIR="$ROOT_DIR/dist"
STAGING_DIR="$DIST_DIR/dmg-staging"
DMG_PATH="$DIST_DIR/$APP_NAME-$VERSION.dmg"
VOLUME_NAME="$APP_NAME $VERSION"

"$ROOT_DIR/scripts/build-app.sh"

rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
mkdir -p "$DIST_DIR"

cp -R "$APP_PATH" "$STAGING_DIR/$APP_NAME.app"
ln -s /Applications "$STAGING_DIR/Applications"

rm -f "$DMG_PATH"
hdiutil create \
    -volname "$VOLUME_NAME" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

hdiutil verify "$DMG_PATH"

rm -rf "$STAGING_DIR"

echo "$DMG_PATH"
