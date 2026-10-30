#!/usr/bin/env sh

set -e

[ -f '.env' ] && source '.env'

start_dir="$(pwd)"

[ $# -lt 1 ] && echo "Usage: ./archive.sh <version>" >&2 && exit 1

# go to repo dir
cd "$(dirname "$0")"

VERSION="$1"
FOLDER_NAME="doot_season_v$VERSION"
ZIP_NAME="$FOLDER_NAME.zip"

# Generate single .lua file
cd src
lua compiler.lua
cd ..

[ ! -d artefacts ] && mkdir artefacts

cd artefacts

mkdir -p tmp/reframework/autorun
mv ../src/output.lua tmp/reframework/autorun/doot_season.lua

cat > tmp/modinfo.ini <<EOF
name=Doot Season
version=$VERSION
description=Doots when you doot. That's at least 60% more doot per doot.
screenshot=screenshot.png
author=HoloTheDrunk
EOF

# Shrink image if possible
if command -v magick >/dev/null 2>&1; then
  magick ../images/screenshot.png -resize 1280x720\> tmp/screenshot.png
else
  cp ../images/screenshot.png tmp/
fi

mv tmp "$FOLDER_NAME"
[ -e "$ZIP_NAME" ] && rm "$ZIP_NAME"
zip -r "$ZIP_NAME" "$FOLDER_NAME"
rm -rf "$FOLDER_NAME"

cd "$start_dir"
