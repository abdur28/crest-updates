#!/bin/bash
#
# Crest release pipeline: archive -> Developer ID export -> notarize -> staple
# -> zip -> (re)generate signed appcast.xml -> commit & push.
#
# Usage:  ./release.sh <version>      e.g.  ./release.sh 2.3.4
# Prereq: one-time `xcrun notarytool store-credentials crest-notary ...` (see README).
#
set -euo pipefail

VERSION="${1:?usage: ./release.sh <version>   e.g. ./release.sh 2.3.4}"

PROJECT="/Users/abdurrahman/Codes/Atoll/DynamicIsland.xcodeproj"
SCHEME="DynamicIsland"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$REPO_DIR/.build"
ARCHIVE="$BUILD_DIR/Crest.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
NOTARY_PROFILE="crest-notary"
DL_PREFIX="https://raw.githubusercontent.com/abdur28/crest-updates/main/"

# Locate Sparkle's generate_appcast (override with GENERATE_APPCAST=... if needed)
GENERATE_APPCAST="${GENERATE_APPCAST:-$(find "$HOME/Library/Developer/Xcode/DerivedData" \
  -path '*sparkle/Sparkle/bin/generate_appcast' 2>/dev/null | head -1)}"
[ -x "$GENERATE_APPCAST" ] || { echo "ERROR: generate_appcast not found; set GENERATE_APPCAST=/path/to/generate_appcast"; exit 1; }

echo "▶︎ Cleaning…";        rm -rf "$BUILD_DIR"; mkdir -p "$BUILD_DIR"
echo "▶︎ Archiving…";       xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Release \
                              -archivePath "$ARCHIVE" archive
echo "▶︎ Exporting (Developer ID)…"
xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$REPO_DIR/ExportOptions.plist"

APP="$EXPORT_DIR/Crest.app"
ZIP="$REPO_DIR/Crest-$VERSION.zip"

echo "▶︎ Zipping for notarization…"; ditto -c -k --keepParent "$APP" "$ZIP"
echo "▶︎ Notarizing (this waits for Apple)…"
xcrun notarytool submit "$ZIP" --keychain-profile "$NOTARY_PROFILE" --wait
echo "▶︎ Stapling…";        xcrun stapler staple "$APP"
echo "▶︎ Re-zipping stapled app…"; rm -f "$ZIP"; ditto -c -k --keepParent "$APP" "$ZIP"

echo "▶︎ Generating signed appcast.xml…"
"$GENERATE_APPCAST" --download-url-prefix "$DL_PREFIX" "$REPO_DIR"

echo "▶︎ Committing & pushing…"
cd "$REPO_DIR"
git add -A
git commit -m "Crest $VERSION"
git push

echo "✅ Published Crest $VERSION"
