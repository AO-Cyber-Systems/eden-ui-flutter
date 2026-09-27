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

# ONE VIOLATION PER RULE. Each of the three rules carries its OWN
# `enforced_paths` (and two carry their own `legacy_exemptions`), so each is
# INDEPENDENTLY exposed to failure mode 3 below. A probe that tripped only
# two of them left text_style_needs_family free to be mis-indented into
# matching nothing for ever while this control printed OK.
cat > "$PROBE" <<'DART'
// TEMPORARY, written and deleted by tool/lint_gate_assert.sh. If you are
// reading this in a commit, the script died between writing and cleaning up
// and this file must be deleted.
import 'package:flutter/material.dart';

Widget zzLintGateProbe() {
  return Container(
    padding: const EdgeInsets.all(7),
    color: const Color(0xFF123456),
    child: const Text('x', style: TextStyle(fontSize: 13)),
  );
}
DART

# The rules that MUST each report. Kept as one list so adding a rule to
# analysis_options.yaml without adding a violation here is a one-line fix in
# an obvious place.
RULES=(no_raw_color no_magic_spacing text_style_needs_family)

OUT="$(dart run custom_lint 2>&1)"
STATUS=$?

if [ "$STATUS" -eq 0 ]; then
  echo "lint gate assert: FAILED -- custom_lint exited 0 on a file that"
  echo "breaks all of ${RULES[*]} inside the enforced scope."
  echo "The gate is not running (or could not analyse the probe at all)."
  echo "Check, in this order:"
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

# NON-ZERO IS NOT ENOUGH. custom_lint exits non-zero for a plugin crash or an
# analysis error raised while analysing the probe too, and a file this script
# just wrote is a likely thing to raise one. Matching on the probe's NAME
# accepted all of those. Each RULE has to be named, on a line that also names
# the probe, or the control has proved something other than "the rules fired".
MISSING=()
MATCHED=""
for RULE in "${RULES[@]}"; do
  LINE="$(echo "$OUT" | grep "zz_lint_gate_probe.dart" | grep " $RULE " | head -1)"
  if [ -z "$LINE" ]; then
    MISSING+=("$RULE")
  else
    MATCHED="$MATCHED
  $LINE"
  fi
done

if [ "${#MISSING[@]}" -ne 0 ]; then
  echo "lint gate assert: FAILED -- custom_lint exited $STATUS but these"
  echo "rules never reported the probe: ${MISSING[*]}"
  echo "A rule that stays quiet on a file written to violate it is a rule"
  echo "that is not running; each one carries its own enforced_paths, so"
  echo "check that rule's block specifically."
  echo "--- custom_lint said ---"
  echo "$OUT"
  exit 1
fi

# THE EVIDENCE, IN THE CI LOG. Printing only "OK" made a passing run
# unreviewable: nothing recorded WHICH rules fired, so a control that had
# silently narrowed to one rule looked exactly like one covering three.
echo "lint gate assert: OK -- custom_lint exited $STATUS and all"
echo "${#RULES[@]} rules reported the probe:$MATCHED"
exit 0
