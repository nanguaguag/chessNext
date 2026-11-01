#!/usr/bin/env bash
# Run from any directory; fail before committing if any gate fails.
set -euo pipefail
cd "$(dirname "$0")/.."
flutter test
flutter analyze
(
  cd packages/xiangqi_core
  dart test
  dart analyze
)
(
  cd research/spikes/flutter_engine_probe
  PIKAFISH_DIR="$PWD/../../../.local/pikafish" flutter test
  flutter analyze
)
# Native UI checks are opt-in because they build and launch a desktop window.
if [[ "${CHECK_MACOS_INTEGRATION:-0}" == "1" ]]; then
  flutter test integration_test/local_board_test.dart -d macos
fi
