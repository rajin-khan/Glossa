#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
LAUNCH_ARGS=("${@:2}")
APP_NAME="Glossa"
BUNDLE_ID="com.rajin.glossa"
MIN_SYSTEM_VERSION="15.0"
APP_VERSION="${GLOSSA_APP_VERSION:-0.1.5}"
BUILD_NUMBER="${GLOSSA_BUILD_NUMBER:-1}"
BUILD_CONFIGURATION="${GLOSSA_BUILD_CONFIGURATION:-debug}"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
LOCAL_CACHE="$ROOT_DIR/.build/cache"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
ICON_SOURCE="$ROOT_DIR/Assets/Glossa-AppIcon.png"
MARK_TEMPLATE_SOURCE="$ROOT_DIR/Assets/Glossa-MarkTemplate.png"
ICONSET_DIR="$ROOT_DIR/.build/Glossa.iconset"

mkdir -p "$LOCAL_CACHE" "$ROOT_DIR/.build/module-cache"
export XDG_CACHE_HOME="$LOCAL_CACHE"
export CLANG_MODULE_CACHE_PATH="$ROOT_DIR/.build/module-cache"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

swift build --configuration "$BUILD_CONFIGURATION"
BUILD_BINARY="$(swift build --configuration "$BUILD_CONFIGURATION" --show-bin-path)/$APP_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"

rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"
/usr/bin/sips -z 16 16 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
/usr/bin/sips -z 32 32 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
/usr/bin/sips -z 32 32 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
/usr/bin/sips -z 64 64 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
/usr/bin/sips -z 128 128 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
/usr/bin/sips -z 256 256 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
/usr/bin/sips -z 256 256 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
/usr/bin/sips -z 512 512 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
/usr/bin/sips -z 512 512 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
cp "$ICON_SOURCE" "$ICONSET_DIR/icon_512x512@2x.png"
/usr/bin/iconutil --convert icns "$ICONSET_DIR" --output "$APP_RESOURCES/Glossa.icns"
cp "$ICON_SOURCE" "$APP_RESOURCES/Glossa-AppIcon.png"
cp "$MARK_TEMPLATE_SOURCE" "$APP_RESOURCES/Glossa-MarkTemplate.png"

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundleIconFile</key>
  <string>Glossa</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$APP_VERSION</string>
  <key>CFBundleVersion</key>
  <string>$BUILD_NUMBER</string>
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.utilities</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
  <key>NSAudioCaptureUsageDescription</key>
  <string>Glossa captures system audio so it can create translated subtitles for media playing on your Mac.</string>
  <key>NSMicrophoneUsageDescription</key>
  <string>Glossa can use your microphone as a fallback caption source when you choose microphone capture.</string>
</dict>
</plist>
PLIST

if [[ "$CODESIGN_IDENTITY" == "-" ]]; then
  /usr/bin/codesign \
    --force \
    --deep \
    --sign - \
    --identifier "$BUNDLE_ID" \
    --requirements "=designated => identifier \"$BUNDLE_ID\"" \
    "$APP_BUNDLE"
else
  /usr/bin/codesign \
    --force \
    --deep \
    --options runtime \
    --timestamp \
    --sign "$CODESIGN_IDENTITY" \
    "$APP_BUNDLE"
fi

open_app() {
  if [[ ${#LAUNCH_ARGS[@]} -gt 0 ]]; then
    /usr/bin/open -n "$APP_BUNDLE" --args "${LAUNCH_ARGS[@]}"
  else
    /usr/bin/open -n "$APP_BUNDLE"
  fi
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  --build-only|build-only)
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify|--build-only]" >&2
    exit 2
    ;;
esac
