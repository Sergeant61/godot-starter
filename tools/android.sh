#!/usr/bin/env bash
# Exports a debug APK with the "Android" preset and installs it on the connected phone or emulator.
#   tools/android.sh              debug build: Google's test ad units, prints to logcat under "godot"
#   tools/android.sh release      release build: the real ad units, signed with the keystore in
#                                 GODOT_ANDROID_KEYSTORE_RELEASE_PATH/USER/PASSWORD
# The two are signed with different keys, so adb refuses to install one over the other and says so
# only in its own output; the package is uninstalled first to keep that from looking like success.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
ADB="${ADB:-$HOME/Library/Android/sdk/platform-tools/adb}"
MODE="${1:-debug}"
PACKAGE=$(sed -n 's/^package\/unique_name="\(.*\)"/\1/p' export_presets.cfg | head -1)
APK=$(sed -n 's/^export_path="\(.*\.apk\)"/\1/p' export_presets.cfg | head -1)

mkdir -p build && touch build/.gdignore
"$GODOT" --headless --import
"$GODOT" --headless "--export-$MODE" "Android" "$APK"
"$ADB" uninstall "$PACKAGE" >/dev/null 2>&1 || true
"$ADB" install "$APK"
"$ADB" shell monkey -p "$PACKAGE" 1 >/dev/null
echo "Running $PACKAGE ($MODE)"
