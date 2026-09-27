#!/usr/bin/env bash
# The guard's JUDGEMENT, split out from the build so it can be TESTED.
#
# tool/probe_guard.sh does the two slow `flutter build web` runs and hands the
# two resulting bundles here. This file contains every decision the guard
# makes, and test/probe/probe_guard_test.dart drives it against hand-built
# fixture bundles -- so the guard's grep logic is itself proven to fail when it
# should, rather than being a script nobody ever watched go red
# (cf. edenbiz-migration-gate-is-dead).
#
# Usage: tool/probe_guard_assert.sh <production-bundle> <probe-bundle>
set -euo pipefail

PROD_BUNDLE="$1"
PROBE_BUNDLE="$2"

for f in "$PROD_BUNDLE" "$PROBE_BUNDLE"; do
  [ -f "$f" ] || {
    echo "FAIL: no bundle at $f -- the build did not produce one, so the"
    echo "      guard has nothing to prove and must not report success"
    exit 2
  }
done

# GOTCHA: `grep -c` exits 1 on ZERO matches, and zero is the answer we WANT for
# the production bundle. Without `|| true` this script would fail for the right
# answer under `set -e`.
PROD_HITS=$(grep -c __edenProbe "$PROD_BUNDLE" || true)
PROBE_HITS=$(grep -c __edenProbe "$PROBE_BUNDLE" || true)

echo "production bundle: $PROD_HITS   probe bundle: $PROBE_HITS"

[ "$PROD_HITS" -eq 0 ] || {
  echo "FAIL: __edenProbe found in a production bundle"
  exit 1
}
# THE DIFFERENTIAL CONTROL. Without this, the check above passes identically
# for a bundle that was tree-shaken and for one that never contained the bridge
# under any conditions.
[ "$PROBE_HITS" -gt 0 ] || {
  echo "FAIL: __edenProbe absent even WITH the define -- the guard is inert"
  exit 1
}

echo "OK: bridge present under the define, absent without it"
