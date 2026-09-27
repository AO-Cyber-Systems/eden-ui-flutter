#!/usr/bin/env bash
# NON-VACUITY CONTROL FOR THE LINT GATE.
#
# `dart run custom_lint` prints "No issues found!" and exits 0 in TWO
# different situations: when the design rules hold, and when the rules are not
# running at all. The second has already happened twice in this repo's short
# history -- once when `analyzer: plugins: custom_lint` went missing (a
# workspace without it is skipped silently, see analysis_options.yaml), and
# once when `enforced_paths` was indented UNDER the rule name instead of
# beside it, which parses fine, yields an empty options map, and makes every
# rule match nothing.
#
# A gate whose unmeasurable state is indistinguishable from its passing state
# is not a gate. So this script writes a file that MUST be reported, runs the
# gate, and fails if the gate stays quiet.
#
# It is deliberately the inverse of the gate: exit 0 here means "the gate
# fired, as it must". Run it AFTER the real gate, never instead of it.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Inside the wave-1 enforced scope declared in analysis_options.yaml. If that
# scope is ever widened or moved, this path has to follow it -- which is the
# point: the control is pinned to the same declaration the gate reads.
PROBE="lib/src/widgets/eden_layout/zz_lint_gate_probe.dart"

cleanup() { rm -f "$ROOT/$PROBE"; }
trap cleanup EXIT INT TERM

cat > "$PROBE" <<'DART'
// TEMPORARY, written and deleted by tool/lint_gate_assert.sh. If you are
// reading this in a commit, the script died between writing and cleaning up
// and this file must be deleted.
import 'package:flutter/material.dart';

Widget zzLintGateProbe() {
  return Container(
    padding: const EdgeInsets.all(7),
    color: const Color(0xFF123456),
  );
}
DART

OUT="$(dart run custom_lint 2>&1)"
STATUS=$?

if [ "$STATUS" -eq 0 ]; then
  echo "lint gate assert: FAILED -- custom_lint exited 0 on a file that"
  echo "breaks no_raw_color AND no_magic_spacing inside the enforced scope."
  echo "The gate is not running. Check, in this order:"
  echo "  1. analysis_options.yaml has ONE top-level 'analyzer:' key"
  echo "     (two produce a duplicate mapping and custom_lint throws);"
  echo "  2. it carries 'plugins: - custom_lint';"
  echo "  3. 'enforced_paths' sits at the SAME indentation as the rule name,"
  echo "     not under it;"
  echo "  4. the scope still contains ${PROBE%/*}."
  echo "--- custom_lint said ---"
  echo "$OUT"
  exit 1
fi

if ! echo "$OUT" | grep -q "zz_lint_gate_probe.dart"; then
  echo "lint gate assert: FAILED -- custom_lint exited non-zero but never"
  echo "named the probe file, so it went red for some other reason and this"
  echo "control proved nothing."
  echo "--- custom_lint said ---"
  echo "$OUT"
  exit 1
fi

echo "lint gate assert: OK -- the gate reported the probe and exited $STATUS."
exit 0
