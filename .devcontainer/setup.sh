#!/usr/bin/env bash
# Post-create bootstrap for the HabitView dev container / Codespace.
#
# Runs the toolchain-dependent steps that could NOT be run in the authoring
# environment (no Dart/Flutter SDK there). After this completes, the code is
# actually compilable and the verification gates in
# docs/CODESPACES_VALIDATION.md can be run.
set -euo pipefail

echo "==> Flutter version"
flutter --version

echo "==> flutter pub get"
flutter pub get

echo "==> build_runner (Isar entities + freezed models -> *.g.dart / *.freezed.dart)"
dart run build_runner build --delete-conflicting-outputs

echo
echo "Bootstrap complete. Recommended next steps:"
echo "  flutter analyze"
echo "  flutter test"
echo "See docs/CODESPACES_VALIDATION.md for the full verification checklist."
