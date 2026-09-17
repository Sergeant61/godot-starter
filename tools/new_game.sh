#!/usr/bin/env bash
# Copies this starter into a new game project next to it, with its own git repo.
# Usage: tools/new_game.sh <folder-name> "<Game Title>"
set -euo pipefail
[ $# -eq 2 ] || { echo "Usage: $0 <folder-name> \"<Game Title>\""; exit 1; }

SRC="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$(dirname "$SRC")/$1"
[ ! -e "$DEST" ] || { echo "$DEST already exists"; exit 1; }

rsync -a --exclude .git --exclude .godot --exclude build "$SRC/" "$DEST/"
sed -i '' "s|^config/name=.*|config/name=\"$2\"|" "$DEST/project.godot"
git -C "$DEST" init -q
git -C "$DEST" add -A
git -C "$DEST" commit -qm "Start from godot-starter"
echo "Created $DEST"
