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
cd "$APP_DIR"

BUNDLE="build/web/main.dart.js"

flutter build web --release
# GOTCHA: `grep -c` exits 1 on ZERO matches, and zero is the answer we WANT
# here. Without `|| true` this script fails for the right answer under `set -e`.
PROD_HITS=$(grep -c __edenProbe "$BUNDLE" || true)

flutter build web --release --dart-define=EDEN_PROBE=true
PROBE_HITS=$(grep -c __edenProbe "$BUNDLE" || true)

echo "production bundle: $PROD_HITS   probe bundle: $PROBE_HITS"

[ "$PROD_HITS" -eq 0 ] || {
  echo "FAIL: __edenProbe found in a production bundle"
  exit 1
}
[ "$PROBE_HITS" -gt 0 ] || {
  echo "FAIL: __edenProbe absent even WITH the define -- the guard is inert"
  exit 1
}

echo "OK: bridge present under the define, absent without it"
