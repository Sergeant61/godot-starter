#!/usr/bin/env bash
# Exports the "Web" preset to build/web and serves it at http://localhost:8000
# (localhost puts the CrazyGames SDK in local mode with demo ads).
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"

mkdir -p build/web
"$GODOT" --headless --import
"$GODOT" --headless --export-release "Web" build/web/index.html
echo "Serving http://localhost:8000"
python3 -m http.server 8000 --directory build/web
