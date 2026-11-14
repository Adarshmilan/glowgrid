#!/usr/bin/env bash
# Builds a signed Play Store bundle: build/GlowGrid-release.aab
# Before each new upload, bump version/code (and version/name) in export_presets.cfg [preset.1.options].
set -euo pipefail
cd "$(dirname "$0")"
PW=$(grep "Store password" keystore/KEYSTORE_INFO.txt | awk '{print $3}')
export JAVA_HOME="$HOME/.local/jdk/jdk-17.0.21+9"
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$PWD/keystore/glowgrid-release.keystore"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="glowgrid"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$PW"
mkdir -p build
[ -d android/build ] || INSTALL="--install-android-build-template"
godot4 --headless --path . ${INSTALL:-} --export-release "Android Release AAB" build/GlowGrid-release.aab
"$JAVA_HOME/bin/jarsigner" -verify build/GlowGrid-release.aab
echo "Done: build/GlowGrid-release.aab"
