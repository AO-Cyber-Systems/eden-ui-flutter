#!/usr/bin/env bash
# Proves the probe bridge is tree-shaken out of a production web bundle.
#
# BOTH directions, one script. A guard that only checked the production build
# would pass identically for a bundle that was tree-shaken and for one that
# never contained the bridge under any conditions -- i.e. it would prove
# nothing. The second assertion is the differential control.
#
# Usage: tool/probe_guard.sh [app-dir]
#   app-dir defaults to example/probe_smoke. Parameterised so W1c can reuse
#   this script against a consumer app rather than copying it.
set -euo pipefail

APP_DIR="${1:-example/probe_smoke}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$APP_DIR"

BUNDLE="build/web/main.dart.js"
OUT="$(mktemp -d)"
trap 'rm -rf "$OUT"' EXIT

flutter build web --release
cp "$BUNDLE" "$OUT/production.js"

flutter build web --release --dart-define=EDEN_PROBE=true
cp "$BUNDLE" "$OUT/probe.js"

# Every decision lives in the assert script, which has its own tests.
bash "$REPO_ROOT/tool/probe_guard_assert.sh" "$OUT/production.js" "$OUT/probe.js"
