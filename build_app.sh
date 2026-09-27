#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "Building JustNotch..."
swift build -c release

APP_NAME="JustNotch"
BUNDLE_DIR="$DIR/${APP_NAME}.app"
CONTENTS_DIR="$BUNDLE_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

rm -rf "$BUNDLE_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

cp "$DIR/.build/release/$APP_NAME" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"

if [ -f "$DIR/Resources/AppIcon.icns" ]; then
    cp "$DIR/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

if [ -f "$DIR/Resources/AppLogo.png" ]; then
    cp "$DIR/Resources/AppLogo.png" "$RESOURCES_DIR/AppLogo.png"
fi

cat << 'EOF' > "$CONTENTS_DIR/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>JustNotch</string>
    <key>CFBundleIdentifier</key>
    <string>com.justnotch.app</string>
    <key>CFBundleName</key>
    <string>JustNotch</string>
    <key>CFBundleDisplayName</key>
    <string>JustNotch</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>JustNotch uses AppleScript to interact with media players.</string>
</dict>
</plist>
EOF

codesign --force --deep --sign - "$BUNDLE_DIR" 2>/dev/null || true

# 1. Create ZIP package
rm -f "$DIR/${APP_NAME}.zip"
ditto -c -k --sequesterRsrc --keepParent "$BUNDLE_DIR" "$DIR/${APP_NAME}.zip"

# 2. Create DMG package with Applications symlink
rm -f "$DIR/${APP_NAME}.dmg"
DMG_TEMP="/tmp/${APP_NAME}_DMG_STAGING"
rm -rf "$DMG_TEMP"
mkdir -p "$DMG_TEMP"
cp -R "$BUNDLE_DIR" "$DMG_TEMP/"
ln -s /Applications "$DMG_TEMP/Applications"
hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_TEMP" -ov -format UDZO "$DIR/${APP_NAME}.dmg" > /dev/null 2>&1
rm -rf "$DMG_TEMP"

echo "Build complete!"
echo "App: $BUNDLE_DIR"
echo "DMG: $DIR/${APP_NAME}.dmg"
echo "ZIP: $DIR/${APP_NAME}.zip"
