#!/usr/bin/env bash
set -euo pipefail
scenario_path="${1:-docs/balance/BAL-TOOLS/scenarios/baseline.json}"
output_path="${2:-/tmp/feed-the-hole-balance}"
source_commit="$(git rev-parse HEAD)"
app_version="$(sed -n 's/^version: //p' pubspec.yaml)"
source_dirty="$(git status --porcelain)"
if [[ -n "$source_dirty" ]]; then source_commit="$source_commit-dirty"; fi
flutter test --no-pub --reporter expanded tool/balance_simulate.dart \
  --dart-define="BAL_SCENARIOS=$scenario_path" --dart-define="BAL_OUTPUT=$output_path" \
  --dart-define="SOURCE_COMMIT=$source_commit" --dart-define="APP_VERSION=$app_version"
