#!/bin/bash
set -e

echo "=== PathDeck macOS App Bundle Builder ==="

# Define directories
WORKSPACE_DIR="$(pwd)"
SCRIPTS_DIR="$WORKSPACE_DIR/scripts"
BUILD_DIR="$WORKSPACE_DIR/.build"
OUTPUT_APP_DIR="$WORKSPACE_DIR/PathDeck.app"
OUTPUT_DMG="$WORKSPACE_DIR/PathDeck.dmg"

# Set DEVELOPER_DIR to Xcode-beta if present locally and not already set in environment
if [ -z "$DEVELOPER_DIR" ] && [ -d "/Applications/Xcode-beta.app/Contents/Developer" ]; then
    export DEVELOPER_DIR="/Applications/Xcode-beta.app/Contents/Developer"
fi

echo "1. Building Swift Package executable in Release mode..."
swift build -c release

echo "2. Re-creating PathDeck.app bundle directory structure..."
rm -rf "$OUTPUT_APP_DIR"
mkdir -p "$OUTPUT_APP_DIR/Contents/MacOS"
mkdir -p "$OUTPUT_APP_DIR/Contents/Resources"

echo "3. Copying compiled binary into app bundle..."
cp "$BUILD_DIR/release/PathDeck" "$OUTPUT_APP_DIR/Contents/MacOS/PathDeck"

echo "4. Copying info.plist..."
cp "$SCRIPTS_DIR/info.plist" "$OUTPUT_APP_DIR/Contents/Info.plist"

# iconutil consumes a .iconset directory with Apple's size and scale filenames.
ICON_SOURCE="$WORKSPACE_DIR/sources/pathdeck/resources/assets.xcassets/appicon.appiconset"
ICON_TEMP=$(mktemp -d)
trap 'rm -rf "$ICON_TEMP"' EXIT
ICON_SET="$ICON_TEMP/appicon.iconset"
mkdir "$ICON_SET"
for size in 16 32 128 256 512; do
    for scale in "" "@2x"; do
        cp "$ICON_SOURCE/icon_${size}x${size}${scale}.png" "$ICON_SET/"
    done
done
iconutil -c icns "$ICON_SET" -o "$OUTPUT_APP_DIR/Contents/Resources/appicon.icns"

echo "5. Performing ad-hoc codesigning on PathDeck.app..."
codesign --force --deep --sign - "$OUTPUT_APP_DIR"

echo "6. Packaging PathDeck.app into a compressed DMG disk image..."
rm -f "$OUTPUT_DMG"

DMG_TEMP_DIR="$WORKSPACE_DIR/dmg_temp"
rm -rf "$DMG_TEMP_DIR"
mkdir -p "$DMG_TEMP_DIR"
cp -R "$OUTPUT_APP_DIR" "$DMG_TEMP_DIR/PathDeck.app"
ln -s /Applications "$DMG_TEMP_DIR/Applications"

hdiutil create -volname "PathDeck" -srcfolder "$DMG_TEMP_DIR" -ov -format UDZO "$OUTPUT_DMG"
rm -rf "$DMG_TEMP_DIR"

echo "========================================="
echo "PathDeck.app and PathDeck.dmg built successfully!"
echo "App location: $OUTPUT_APP_DIR"
echo "DMG location: $OUTPUT_DMG"
echo "========================================="
