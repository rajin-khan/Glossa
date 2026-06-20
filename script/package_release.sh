#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Glossa"
VERSION="${GLOSSA_APP_VERSION:-0.1.4}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
ARCHIVE="$DIST_DIR/$APP_NAME-$VERSION-macOS.zip"
DMG_STAGE="$DIST_DIR/dmg-stage"
DMG_RW="$DIST_DIR/$APP_NAME-$VERSION-macOS-rw.dmg"
DMG="$DIST_DIR/$APP_NAME-$VERSION-macOS.dmg"
CHECKSUMS="$DIST_DIR/SHA256SUMS.txt"

export GLOSSA_BUILD_CONFIGURATION=release
export GLOSSA_APP_VERSION="$VERSION"

"$ROOT_DIR/script/build_and_run.sh" --build-only

/usr/bin/plutil -lint "$APP_BUNDLE/Contents/Info.plist"
/usr/bin/codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

rm -f "$ARCHIVE" "$DMG_RW" "$DMG" "$CHECKSUMS"
rm -rf "$DMG_STAGE"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$APP_BUNDLE" "$ARCHIVE"

mkdir -p "$DMG_STAGE"
/usr/bin/ditto "$APP_BUNDLE" "$DMG_STAGE/$APP_NAME.app"
ln -s /Applications "$DMG_STAGE/Applications"
/usr/bin/hdiutil create \
  -volname "$APP_NAME $VERSION" \
  -srcfolder "$DMG_STAGE" \
  -ov \
  -format UDRW \
  "$DMG_RW" >/dev/null

VOLUME_PATH=""
if ATTACH_OUTPUT="$(/usr/bin/hdiutil attach -readwrite -noverify -noautoopen "$DMG_RW")"; then
  VOLUME_PATH="$(printf '%s\n' "$ATTACH_OUTPUT" | awk '/\/Volumes\// {print substr($0, index($0, "/Volumes/")); exit}')"
  if [[ -n "$VOLUME_PATH" ]]; then
    /usr/bin/osascript <<OSA >/dev/null 2>&1 || true
tell application "Finder"
  tell disk "$APP_NAME $VERSION"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set bounds of container window to {200, 120, 720, 440}
    set viewOptions to the icon view options of container window
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to 96
    set position of item "$APP_NAME.app" of container window to {160, 150}
    set position of item "Applications" of container window to {360, 150}
    close
    open
    update without registering applications
  end tell
end tell
OSA
    sync
    /usr/bin/hdiutil detach "$VOLUME_PATH" >/dev/null
  fi
fi

/usr/bin/hdiutil convert "$DMG_RW" -format UDZO -imagekey zlib-level=9 -o "$DMG" >/dev/null
rm -f "$DMG_RW"
rm -rf "$DMG_STAGE"

(
  cd "$DIST_DIR"
  /usr/bin/shasum -a 256 "$(basename "$ARCHIVE")" "$(basename "$DMG")" >"$(basename "$CHECKSUMS")"
)

echo "Packaged $ARCHIVE"
echo "Packaged $DMG"
echo "Checksum written to $CHECKSUMS"

if [[ "${CODESIGN_IDENTITY:--}" == "-" ]]; then
  echo "Signing: stable ad-hoc identity (free local/GitHub development build)"
  echo "Gatekeeper: recipients must use Control-click > Open on first launch"
else
  /usr/sbin/spctl --assess --type execute --verbose=2 "$APP_BUNDLE"
fi
