#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Glossa"
VERSION="${GLOSSA_APP_VERSION:-0.1.2}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
ARCHIVE="$DIST_DIR/$APP_NAME-$VERSION-macOS.zip"
CHECKSUMS="$DIST_DIR/SHA256SUMS.txt"

export GLOSSA_BUILD_CONFIGURATION=release
export GLOSSA_APP_VERSION="$VERSION"

"$ROOT_DIR/script/build_and_run.sh" --build-only

/usr/bin/plutil -lint "$APP_BUNDLE/Contents/Info.plist"
/usr/bin/codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

rm -f "$ARCHIVE" "$CHECKSUMS"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$APP_BUNDLE" "$ARCHIVE"
(
  cd "$DIST_DIR"
  /usr/bin/shasum -a 256 "$(basename "$ARCHIVE")" >"$(basename "$CHECKSUMS")"
)

echo "Packaged $ARCHIVE"
echo "Checksum written to $CHECKSUMS"

if [[ "${CODESIGN_IDENTITY:--}" == "-" ]]; then
  echo "Signing: stable ad-hoc identity (free local/GitHub development build)"
  echo "Gatekeeper: recipients must use Control-click > Open on first launch"
else
  /usr/sbin/spctl --assess --type execute --verbose=2 "$APP_BUNDLE"
fi
