#!/bin/bash
set -euo pipefail

# Builds, signs, notarizes, and packages Maccy for distribution.
#
# Prerequisites:
#   - "Developer ID Application" certificate in the keychain
#   - notarytool keychain profile: xcrun notarytool store-credentials maccy-notary ...
#
# Output: dist/Maccy-<version>.zip (notarized and stapled) and its sha256.

cd "$(dirname "$0")/.."

IDENTITY="Developer ID Application: José Miranda (L228C8LS8X)"
TEAM_ID="L228C8LS8X"
PROFILE="maccy-notary"
OUT=dist

VERSION=$(xcodebuild -project Maccy.xcodeproj -showBuildSettings -configuration Release 2>/dev/null \
  | awk '/MARKETING_VERSION/ { print $3; exit }')
BUILD=$(xcodebuild -project Maccy.xcodeproj -showBuildSettings -configuration Release 2>/dev/null \
  | awk '/CURRENT_PROJECT_VERSION/ { print $3; exit }')
echo "==> Building Maccy $VERSION ($BUILD)"

rm -rf "$OUT"
mkdir -p "$OUT"

xcodebuild -project Maccy.xcodeproj -scheme Maccy -configuration Release \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CODE_SIGN_IDENTITY="$IDENTITY" \
  CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
  OTHER_CODE_SIGN_FLAGS="--timestamp" \
  build

APP=$(find ~/Library/Developer/Xcode/DerivedData/Maccy-*/Build/Products/Release -maxdepth 1 -name Maccy.app | head -1)
cp -R "$APP" "$OUT/"

# Xcode does not re-sign the executables nested inside the prebuilt Sparkle
# framework, and the notary service rejects their original signatures.
# Re-sign them inside-out, then the framework, then the app (whose seal the
# nested re-signing invalidates).
echo "==> Re-signing Sparkle nested binaries"
SPARKLE="$OUT/Maccy.app/Contents/Frameworks/Sparkle.framework"
resign() {
  codesign --force --options runtime --timestamp --preserve-metadata=entitlements \
    --sign "$IDENTITY" "$1"
}
resign "$SPARKLE/Versions/B/XPCServices/Downloader.xpc"
resign "$SPARKLE/Versions/B/XPCServices/Installer.xpc"
resign "$SPARKLE/Versions/B/Autoupdate"
resign "$SPARKLE/Versions/B/Updater.app"
resign "$SPARKLE"
resign "$OUT/Maccy.app"

echo "==> Verifying signature"
codesign --verify --deep --strict "$OUT/Maccy.app"

ZIP="$OUT/Maccy-$VERSION.zip"
ditto -c -k --keepParent "$OUT/Maccy.app" "$ZIP"

echo "==> Notarizing (takes a few minutes)"
xcrun notarytool submit "$ZIP" --keychain-profile "$PROFILE" --wait

echo "==> Stapling notarization ticket"
xcrun stapler staple "$OUT/Maccy.app"

# Re-zip so the published archive contains the stapled app
rm "$ZIP"
ditto -c -k --keepParent "$OUT/Maccy.app" "$ZIP"

# Regenerate the Sparkle appcast (single latest item). Sparkle validates
# updates via Apple code signing (same Developer ID team), so no EdDSA
# signature is needed. Commit and push appcast.xml after publishing the
# GitHub release, or in-app update checks will 404.
echo "==> Writing appcast.xml"
cat > appcast.xml <<APPCAST
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>MaccyCustom</title>
    <link>https://github.com/astrovini/MaccyCustom</link>
    <item>
      <title>$VERSION</title>
      <pubDate>$(date -R)</pubDate>
      <sparkle:version>$BUILD</sparkle:version>
      <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
      <link>https://github.com/astrovini/MaccyCustom/releases/tag/v$VERSION</link>
      <enclosure
        url="https://github.com/astrovini/MaccyCustom/releases/download/v$VERSION/Maccy-$VERSION.zip"
        length="$(stat -f %z "$ZIP")"
        type="application/octet-stream"/>
    </item>
  </channel>
</rss>
APPCAST

echo "==> Done: $ZIP"
shasum -a 256 "$ZIP"
