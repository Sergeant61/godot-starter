#!/usr/bin/env bash
# Copies this starter into a new game project next to it, with its own git repo.
# Usage: tools/new_game.sh <folder-name> "<Game Title>"
# The Android package becomes com.recepozen.<folder name without dashes>; it cannot be changed
# after the first upload to Play, so pick the folder name with that in mind.
set -euo pipefail
[ $# -eq 2 ] || { echo "Usage: $0 <folder-name> \"<Game Title>\""; exit 1; }

SRC="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$(dirname "$SRC")/$1"
[ ! -e "$DEST" ] || { echo "$DEST already exists"; exit 1; }
PACKAGE="com.recepozen.$(echo "$1" | tr -d '-_' | tr '[:upper:]' '[:lower:]')"

rsync -a --exclude .git --exclude .godot --exclude build --exclude android "$SRC/" "$DEST/"
sed -i '' "s|^config/name=.*|config/name=\"$2\"|" "$DEST/project.godot"
sed -i '' "s|^package/unique_name=.*|package/unique_name=\"$PACKAGE\"|; \
	s|^package/name=.*|package/name=\"$2\"|; \
	s|^export_path=\"build/android/game\.|export_path=\"build/android/$1.|" "$DEST/export_presets.cfg"
git -C "$DEST" init -q
git -C "$DEST" add -A
git -C "$DEST" commit -qm "Start from godot-starter"
echo "Created $DEST ($PACKAGE)"
