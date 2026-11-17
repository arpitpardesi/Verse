#!/bin/bash
# -----------------------------------------------------------------------------
# Verse Automated Release Script
# Usage:
#   ./release.sh <version> ["Optional release notes"]
#
# Examples:
#   ./release.sh 2.1
#   ./release.sh 2.1 "Major performance optimizations & new Picture Disc CD theme"
# -----------------------------------------------------------------------------
set -e

VERSION="$1"
NOTES="$2"

if [ -z "$VERSION" ]; then
    echo "❌ Error: Please specify a version number."
    echo "Usage: ./release.sh <version> [\"Optional release notes\"]"
    echo "Example: ./release.sh 2.1"
    exit 1
fi

# Strip leading 'v' if provided (e.g. v2.1 -> 2.1)
VERSION="${VERSION#v}"
TAG="v$VERSION"

echo "🚀 Preparing release for Verse $TAG..."

# 1. Update version strings in build.sh and Core.swift
sed -i '' "s/<key>CFBundleShortVersionString<\/key><string>.*<\/string>/<key>CFBundleShortVersionString<\/key><string>$VERSION<\/string>/" build.sh
sed -i '' "s/<key>CFBundleVersion<\/key><string>.*<\/string>/<key>CFBundleVersion<\/key><string>$VERSION<\/string>/" build.sh
sed -i '' "s/static let version = \".*\"/static let version = \"$VERSION\"/" Sources/Verse/Core.swift

# 2. Build and package Verse.app
echo "🔨 Building release binary and signing Verse.app..."
./build.sh --no-open

# 3. Create zip archive using ditto (preserves Mac file metadata and signatures)
echo "📦 Packaging Verse.zip..."
rm -f Verse.zip
ditto -c -k --keepParent Verse.app Verse.zip

# 4. If /Applications/Verse.app exists, upgrade it locally and relaunch
if [ -d "/Applications/Verse.app" ]; then
    echo "📲 Upgrading local installation at /Applications/Verse.app..."
    pkill -x Verse 2>/dev/null || true
    sleep 0.6
    rm -rf "/Applications/Verse.app"
    cp -R "Verse.app" "/Applications/Verse.app"
    xattr -cr "/Applications/Verse.app" 2>/dev/null || true
    open "/Applications/Verse.app"
    echo "🎉 Relaunched updated Verse $TAG in /Applications!"
fi

# 5. Commit and Tag
echo "🏷️  Tagging $TAG in git..."
git add build.sh Sources/Verse/Core.swift
git commit -m "chore(release): bump version to $VERSION" || true
git tag -fa "$TAG" -m "Verse $TAG"

# 6. Push commit & tag to GitHub (Triggers GitHub Actions CI/CD)
echo "☁️  Pushing to GitHub..."
git push origin main || true
git push origin "$TAG" --force

# 7. If GitHub CLI (gh) is installed, publish release directly
if command -v gh >/dev/null 2>&1; then
    echo "✨ Publishing GitHub Release via gh CLI..."
    if [ -n "$NOTES" ]; then
        gh release create "$TAG" Verse.zip --title "Verse $TAG" --notes "$NOTES"
    else
        gh release create "$TAG" Verse.zip --title "Verse $TAG" --generate-notes
    fi
else
    echo "💡 Note: GitHub CLI (gh) is not installed."
    echo "   The GitHub Actions workflow has been triggered by pushing $TAG."
    echo "   GitHub will automatically build, package, and attach Verse.zip to your release."
    echo "   Release URL: https://github.com/arpitpardesi/Verse/releases/tag/$TAG"
fi

echo "✅ Verse $TAG is live! Users will automatically receive the OTA update."
