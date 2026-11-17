#!/bin/bash
# Builds Verse.app (needs Xcode command line tools: xcode-select --install)
set -e
swift build -c release
APP=Verse.app
rm -rf "$APP"; mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/Verse "$APP/Contents/MacOS/Verse"
if [ -f Resources/AppIcon.icns ]; then
    cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
fi
cat > "$APP/Contents/Info.plist" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>Verse</string>
<key>CFBundleIdentifier</key><string>com.local.verse</string>
<key>CFBundleName</key><string>Verse</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>2.0</string>
<key>CFBundleVersion</key><string>2.0</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundleIconName</key><string>AppIcon</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
<key>NSAppleEventsUsageDescription</key><string>Verse reads the current song from Spotify and Apple Music to show synced lyrics.</string>
<key>NSCameraUsageDescription</key><string>Verse uses the camera for hands-free face detection to wake the display when you sit down.</string>
</dict></plist>
PL
codesign --force --sign - "$APP"
echo "Built $APP — drag it to /Applications and open it."
if [ "$1" != "--no-open" ] && [ -z "$NO_OPEN" ]; then
    open "$APP"
fi
