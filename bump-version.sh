#!/bin/sh
################################################################################
# This script updates the version number in our export_presets.cfg and
# project.godot files.
#
# Usage:
#   generate-export-presets.sh: Generate a new version number with a "-dev"
#     suffix. 
#   generate-export-presets.sh --release: Finalize the current version,
#     removing the "-dev" suffix.
#   generate-export-presets.sh [VERSION]: Set an explicit version string.

if [ "$1" = "--release" ]; then
  version=$(grep '^config/version=' project/project.godot | cut -d'"' -f2)
  version=${version%-dev}
elif [ "$1" ]
then
  version="$1"
else
# Calculate version string
  seconds=$(date +%s)
  version=$((seconds / 864000 - 2048))
  version=$(printf 0.%02d $version)-dev
fi

echo "version=$version"

# Update export presets
sed -i "s|export_path=\"export/windows/.*\"|export_path=\"export/windows/monster-connect-win-v$version.zip\"|g" project/export_presets.cfg
sed -i "s|export_path=\"export/linux/.*\"|export_path=\"export/linux/monster-connect-linux-v$version.zip\"|g" project/export_presets.cfg
sed -i "s|export_path=\"export/android/.*\"|export_path=\"export/android/monster-connect-android-v$version.apk\"|g" project/export_presets.cfg

# Android version number cannot contain "-dev". Update the version/name property for Android to omit it.
android_version=${version%-dev}
awk -v ver="$android_version" '
  BEGIN { in_android=0 }
  /^\[preset\.[0-9]+\]/ { in_android=0; current=$0 }
  /^platform="Android"/ { in_android=1 }
  in_android && /^\[preset\.[0-9]+\.options\]/ { in_android=2 }
  in_android==2 && /^version\/name=/ { sub(/version\/name=.*/, "version/name=\"" ver "\"") }
  { print }
' project/export_presets.cfg > project/export_presets.cfg.tmp && mv project/export_presets.cfg.tmp project/export_presets.cfg

# Windows file version and product version must have the format "a.b.c.d". Update the versions appropriately.
windows_version=${version%-dev}.0.0
sed -i "s|application/file_version=.*\"|application/file_version=\"$windows_version\"|g" project/export_presets.cfg
sed -i "s|application/product_version=.*\"|application/product_version=\"$windows_version\"|g" project/export_presets.cfg

echo "Updated export_presets.cfg"

# Update project.godot
sed -i "s/^config\/version=\".*\"$/config\/version=\"$version\"/g" project/project.godot
echo "Updated project.godot"
