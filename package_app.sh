#!/bin/bash

set -e # Exit on error

# 1. Determine Version
if [ -n "$1" ]; then
    VERSION="$1"
else
    if [ -f "Sources/ClipPin/Info.plist" ]; then
        VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Sources/ClipPin/Info.plist)
    else
        echo "Error: Sources/ClipPin/Info.plist not found."
        exit 1
    fi
fi

if [ -z "$VERSION" ]; then
    echo "Error: Could not determine version."
    exit 1
fi

echo "📦 Packaging ClipPin v${VERSION}..."

# 2. Clean previous builds
echo "🧹 Cleaning..."
rm -rf .build ClipPin.app *.zip

# 3. Build in Release mode
echo "🏗️  Building (Release)..."
swift build -c release

# Get build path
BUILD_PATH=$(swift build -c release --show-bin-path)

# 4. Create App Bundle
echo "📂 Creating App Bundle..."
mkdir -p ClipPin.app/Contents/MacOS
mkdir -p ClipPin.app/Contents/Resources

# Copy Binary
cp "$BUILD_PATH/ClipPin" ClipPin.app/Contents/MacOS/

# Copy Info.plist
cp Sources/ClipPin/Info.plist ClipPin.app/Contents/

# Copy Resources
cp Sources/ClipPin/Resources/AppIcon.icns ClipPin.app/Contents/Resources/ClipPin.icns
cp Sources/ClipPin/Resources/MenuBarIcon.png ClipPin.app/Contents/Resources/
cp Sources/ClipPin/Resources/MenuBarIcon@2x.png ClipPin.app/Contents/Resources/

# Set executable permissions
chmod +x ClipPin.app/Contents/MacOS/ClipPin

echo "✓ Built ClipPin.app (Release)"

# 5. Package (Zip)
ZIP_NAME="ClipPin-v${VERSION}.zip"
echo "🤐 Zipping to ${ZIP_NAME}..."
ditto -c -k --keepParent ClipPin.app "${ZIP_NAME}"

# 6. Checksum
echo "🔐 Calculating Checksum..."
SHA256=$(shasum -a 256 "${ZIP_NAME}" | awk '{print $1}')

echo ""
echo "✅ Done!"
echo "---------------------------------------------------"
echo "✓ Created ${ZIP_NAME}"
echo "✓ SHA256: ${SHA256}"
echo "---------------------------------------------------"
echo "Next steps:"
echo "1. Test: open ClipPin.app"
echo "2. Create GitHub release for v${VERSION}"
echo "3. Upload ${ZIP_NAME}"
