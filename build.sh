#!/bin/sh
################################################################################
# This script exports and packages the game's release builds for uploading
# to GitHub and itch.io.

# Read the version number from project.godot
version=$(grep "config/version=" project/project.godot | awk -F "\"" '{print $2}')
echo "version=$version"

# Validate that the build properties file exists
if [ ! -f config/build.properties ]; then
  echo "ERROR: Missing config/build.properties."
  echo "Please copy config/build.properties.template and edit it to match your setup."
  exit 1
fi

. config/build.properties

if [ -z "$GODOT_EXE" ]; then
  echo "ERROR: GODOT_EXE is not set in config/build.properties."
  exit 1
fi


################################################################################
# Export all releases

for platform in "Windows" "Linux" "Web" "Android"; do
  echo "Exporting release for $platform"
  "$GODOT_EXE" --headless --path project --export-release "$platform"
done

################################################################################
# Package the windows release

win_export_path="project/export/windows"
win_zip_filename="$win_export_path/monster-connect-win-v$version.zip"
win_bat_filename="$win_export_path/monster-connect-win-troubleshoot-v$version.bat"
win_bat_template="bin/troubleshoot_bat/monster-connect-troubleshoot.bat.template"

# Create and embed the windows bat file
echo "Packaging $win_zip_filename"
cp "$win_bat_template" "$win_bat_filename"
sed -i "s|##WIN_EXE_FILENAME##|monster-connect-win-v$version.exe|g" "$win_bat_filename"
zip -uj "$win_zip_filename" "$win_bat_filename"

# Remove temporary build artifacts
if [ -n "$win_export_path" ] && [ -d "$win_export_path" ]; then
  find "$win_export_path" -type f ! -name "*.zip" -delete
fi

################################################################################
# Package the web release

web_export_path="project/export/web"
web_zip_filename="$web_export_path/monster-connect-web-v$version.zip"
web_src_html_filename="$web_export_path/monster-connect.html"
web_target_html_filename="$web_export_path/index.html"

# Delete the existing web zip file
if [ -f "$web_zip_filename" ]; then
  echo "Deleting $web_zip_filename"
  rm "$web_zip_filename"
fi

# Assemble the web zip file, renaming the index.html file for itch.io
echo "Packaging $web_zip_filename"
mv -f "$web_src_html_filename" "$web_target_html_filename"
zip "$web_zip_filename" "$web_export_path/*" -x "*.zip" "$web_export_path/.*" "*.import" -j

# Remove temporary build artifacts
if [ -n "$web_export_path" ] && [ -d "$web_export_path" ]; then
  find "$web_export_path" -type f ! -name "*.zip" -delete
fi
