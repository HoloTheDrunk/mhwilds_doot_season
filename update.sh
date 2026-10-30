#!/usr/bin/env sh

set -e

[ -f '.env' ] && source '.env'

cd src
lua compiler.lua
mv output.lua "$WILDS_DIR/reframework/autorun/doot_season.lua"
cd -

TARGET_DIR="$WILDS_DIR/reframework/images/doot_season"
[ ! -d "$TARGET_DIR" ] && mkdir "$TARGET_DIR"
cp -r ./assets/images/* "$TARGET_DIR"
