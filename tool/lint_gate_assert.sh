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
# is not a gate. So this script writes files that MUST be reported, runs the
# gate, and fails if the gate stays quiet about any of them.
#
# It is deliberately the inverse of the gate: exit 0 here means "the gate
# fired, as it must". Run it AFTER the real gate, never instead of it.
#
# ---------------------------------------------------------------------------
# WHY THE SCOPE LIST IS READ AND NOT WRITTEN DOWN (eden-ui-flutter#50)
# ---------------------------------------------------------------------------
# This script used to hardcode ONE probe path, in `lib/src/widgets/eden_layout/`,
# with a comment saying "if that scope is ever widened or moved, this path has
# to follow it". It was widened -- `lib/src/widgets/eden_data_display/**` was
# added to all three rules -- and the path did not follow, because nothing made
# it. The control went on passing on the strength of the OLD directory while
# the new one was covered by nothing: a typo or a mis-indent under
# `eden_data_display` would have left it silently ungated with this script,
# `dart run custom_lint` and the whole Lint job green. That is the same
# "reports the same thing for clean and for not looked at" failure this file
# exists to prevent, one directory over.
#
# So the matrix is DERIVED from analysis_options.yaml: every (rule, glob) pair
# the gate actually reads must be independently proved to fire. Widening the
# scope now widens the control in the same edit, and there is no second list to
# forget.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

OPTIONS="analysis_options.yaml"

# The rules that MUST each report, in every scope they declare. Kept explicit
# so a rule ADDED to analysis_options.yaml without a matching violation in the
# probe below is a loud failure here rather than a quietly unproved rule --
# see the cross-check immediately after parsing.
RULES=(no_raw_color no_magic_spacing text_style_needs_family)

# ---------------------------------------------------------------------------
# Parse `custom_lint: rules:` -> one "<rule><TAB><glob>" line per enforced path
# ---------------------------------------------------------------------------
# Deliberately a line-based reader and not a YAML library: this script runs in
# the Lint job before anything but bash and the Dart toolchain exist, and the
# block it reads is three levels of fixed indentation. It tracks the CURRENT
# KEY as well as the current rule, so `legacy_exemptions` entries -- which sit
# at the same indentation as `enforced_paths` entries -- can never be mistaken
# for enforced scopes. Comment lines inside a list are skipped.
#
# POSIX awk ONLY -- no `match($0, re, arr)`. That three-argument form is a GNU
# extension: it is absent from mawk, which is what `awk` resolves to on the
# ubuntu-latest runner this gate runs on, and absent from the BSD awk on a
# macOS workstation. It would have parsed nothing on both, PAIRS would have
# been empty, and the guard below would have turned every Lint run red for a
# reason that has nothing to do with the rules. sub() on a copy is portable.
#
# STRUCTURE IS MATCHED BY POSITION, AND AN UNRECOGNISED SHAPE IS A HARD FAIL.
# The first version keyed the rule header on `/^    - [a-z_]+:$/` and simply
# did not match anything else -- and crucially did NOT reset `rule` when it did
# not match. So a rule whose name contains a digit (`new_rule2`) fell through,
# its `enforced_paths` were attributed to the PREVIOUS rule, and the pair count
# went UP: the control printed "OK -- 7 (rule, scope) pair(s)" while the new
# rule was probed by nothing. Neither guard below could see it -- MISSING_RULES
# iterates a hardcoded list, UNKNOWN_RULES iterates what parsed, and the rule
# was in neither. A higher number that means less coverage is the worst
# possible failure for a control whose whole output is a number.
#
# So every 4-space list item is now matched on POSITION, and a header whose
# remainder is not `<name>:` emits `!MALFORMED` rather than being skipped. Same
# for the 6-space key line, which had the identical latent bug one level down.
PAIRS="$(awk '
  /^custom_lint:[ \t]*$/ { in_cl = 1; next }
  in_cl && /^[^ \t]/     { in_cl = 0 }
  !in_cl { next }
  /^[ \t]*#/ { next }
  # `    - <rule>:`  (4 spaces) starts a new rule and clears the key.
  /^    - / {
    line = $0; sub(/^    - /, "", line); sub(/[ \t]+$/, "", line)
    if (line ~ /^[A-Za-z0-9_]+:$/) {
      sub(/:$/, "", line); rule = line; key = ""
    } else {
      print "!MALFORMED\trule header: " $0
      rule = ""; key = ""
    }
    next
  }
  # `      <key>:`   (6 spaces) selects which list the items below belong to,
  # which is what keeps `legacy_exemptions` entries out of the matrix.
  /^      [^ \t]/ {
    line = $0; sub(/^      /, "", line); sub(/[ \t]+$/, "", line)
    if (line ~ /^[A-Za-z0-9_]+:$/) {
      sub(/:$/, "", line); key = line
    } else {
      print "!MALFORMED\toption key: " $0
      key = ""
    }
    next
  }
  # `        - <value>` (8 spaces) is an item of the current key.
  /^        - / {
    line = $0; sub(/^        - /, "", line); sub(/[ \t]+$/, "", line)
    if (rule != "" && key == "enforced_paths" && line != "") print rule "\t" line
  }
' "$OPTIONS")"

# A SHAPE THE PARSER DOES NOT UNDERSTAND IS NEVER SILENTLY SKIPPED. Skipping is
# how the digit-in-a-name bug produced a bigger number and less coverage.
MALFORMED="$(echo "$PAIRS" | grep '^!MALFORMED' || true)"
if [ -n "$MALFORMED" ]; then
  echo "lint gate assert: FAILED -- $OPTIONS has custom_lint entries this"
  echo "control cannot parse, so it cannot prove they are enforced:"
  echo "$MALFORMED" | sed 's/^!MALFORMED\t/  - /'
  echo "Rule names and option keys must match [A-Za-z0-9_]+ followed by ':'."
  echo "Teach this parser the new shape; do NOT leave the entry unproved."
  exit 1
fi

if [ -z "$PAIRS" ]; then
  echo "lint gate assert: FAILED -- parsed ZERO (rule, enforced_path) pairs"
  echo "out of $OPTIONS. This control cannot build its probe matrix, which is"
  echo "a FAILURE and never a pass: a run that proves nothing must not look"
  echo "like a run that proved everything. Either the custom_lint block moved,"
  echo "or its indentation changed (rule at 4 spaces, key at 6, item at 8)."
  exit 1
fi

# EVERY RULE MUST APPEAR. A rule whose `enforced_paths` list is empty, absent,
# or mis-indented parses to nothing here -- which is exactly the failure mode
# this script was written for, so it must be caught as an absence and not as a
# short loop that iterates over what happens to be present.
PARSED_RULES="$(echo "$PAIRS" | cut -f1 | sort -u)"
MISSING_RULES=()
for RULE in "${RULES[@]}"; do
  echo "$PARSED_RULES" | grep -qx "$RULE" || MISSING_RULES+=("$RULE")
done
if [ "${#MISSING_RULES[@]}" -ne 0 ]; then
  echo "lint gate assert: FAILED -- these rules declare no enforced_paths that"
  echo "this control could read: ${MISSING_RULES[*]}"
  echo "A rule with no scope matches no file and reports nothing, which reads"
  echo "identically to a rule that is holding. Check that rule's block:"
  echo "  * 'enforced_paths' at the SAME indentation as the rule name, not"
  echo "    under it (under it parses fine and yields an empty options map);"
  echo "  * at least one glob beneath it."
  exit 1
fi

# AND NO RULE MAY APPEAR THAT THIS CONTROL DOES NOT PROBE. Adding a fourth
# design rule to analysis_options.yaml without adding a violation to the probe
# below would leave it unproved while every message here still said OK.
UNKNOWN_RULES=()
while IFS= read -r RULE; do
  [ -z "$RULE" ] && continue
  FOUND=0
  for KNOWN in "${RULES[@]}"; do [ "$RULE" = "$KNOWN" ] && FOUND=1; done
  [ "$FOUND" -eq 0 ] && UNKNOWN_RULES+=("$RULE")
done <<< "$PARSED_RULES"
if [ "${#UNKNOWN_RULES[@]}" -ne 0 ]; then
  echo "lint gate assert: FAILED -- $OPTIONS enforces rule(s) this control"
  echo "does not probe: ${UNKNOWN_RULES[*]}"
  echo "Add a violation of each to the probe source in this script and add the"
  echo "name to RULES. An unprobed rule is an unproved rule."
  exit 1
fi

# ---------------------------------------------------------------------------
# One probe file per distinct enforced directory
# ---------------------------------------------------------------------------
# ONE VIOLATION PER RULE, IN EVERY SCOPE. Each rule carries its OWN
# `enforced_paths` (and two carry their own `legacy_exemptions`), so each is
# INDEPENDENTLY exposed to a mis-indent -- and now each SCOPE is too. A probe
# that tripped only two rules left text_style_needs_family free to match
# nothing for ever while this control printed OK; a probe in only one directory
# left every other directory in exactly that state.
PROBE_BASENAME="zz_lint_gate_probe.dart"
PROBES=()

cleanup() {
  for P in "${PROBES[@]:-}"; do [ -n "$P" ] && rm -f "$ROOT/$P"; done
}
trap cleanup EXIT INT TERM

GLOBS="$(echo "$PAIRS" | cut -f2 | sort -u)"
while IFS= read -r GLOB; do
  [ -z "$GLOB" ] && continue
  # Only `<dir>/**` can hold a probe. Any other shape is refused rather than
  # skipped: skipping would shrink the matrix silently, which is the whole
  # defect class this file guards.
  case "$GLOB" in
    */\*\*) DIR="${GLOB%/\*\*}" ;;
    *)
      echo "lint gate assert: FAILED -- enforced path '$GLOB' is not of the"
      echo "form '<dir>/**', so this control cannot place a probe inside it."
      echo "Teach this script the new shape; do NOT leave the scope unproved."
      exit 1
      ;;
  esac
  if [ ! -d "$ROOT/$DIR" ]; then
    echo "lint gate assert: FAILED -- enforced path '$GLOB' names a directory"
    echo "that does not exist: $DIR"
    echo "A glob matching nothing enforces nothing, and reads exactly like a"
    echo "scope that is clean."
    exit 1
  fi
  PROBE="$DIR/$PROBE_BASENAME"
  PROBES+=("$PROBE")
  cat > "$ROOT/$PROBE" <<'DART'
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
done <<< "$GLOBS"

OUT="$(dart run custom_lint 2>&1)"
STATUS=$?

if [ "$STATUS" -eq 0 ]; then
  echo "lint gate assert: FAILED -- custom_lint exited 0 on ${#PROBES[@]} file(s)"
  echo "that each break all of ${RULES[*]} inside the enforced scope."
  echo "The gate is not running (or could not analyse the probes at all)."
  echo "Check, in this order:"
  echo "  1. analysis_options.yaml has ONE top-level 'analyzer:' key"
  echo "     (two produce a duplicate mapping and custom_lint throws);"
  echo "  2. it carries 'plugins: - custom_lint';"
  echo "  3. 'enforced_paths' sits at the SAME indentation as the rule name,"
  echo "     not under it;"
  echo "  4. the probes written were: ${PROBES[*]}"
  echo "--- custom_lint said ---"
  echo "$OUT"
  exit 1
fi

# NON-ZERO IS NOT ENOUGH. custom_lint exits non-zero for a plugin crash or an
# analysis error raised while analysing a probe too, and a file this script
# just wrote is a likely thing to raise one. Matching on the probe's NAME
# accepted all of those. Each RULE has to be named, on a line that also names
# the probe IN THAT SCOPE, or the control has proved something other than
# "the rules fired everywhere they are declared to".
MISSING=()
MATCHED=""
while IFS=$'\t' read -r RULE GLOB; do
  [ -z "$RULE" ] && continue
  DIR="${GLOB%/\*\*}"
  PROBE="$DIR/$PROBE_BASENAME"
  LINE="$(echo "$OUT" | grep -F "$PROBE" | grep " $RULE " | head -1)"
  if [ -z "$LINE" ]; then
    MISSING+=("$RULE @ $GLOB")
  else
    MATCHED="$MATCHED
  $LINE"
  fi
done <<< "$PAIRS"

if [ "${#MISSING[@]}" -ne 0 ]; then
  echo "lint gate assert: FAILED -- custom_lint exited $STATUS but these"
  echo "(rule, scope) pairs never reported their probe:"
  for M in "${MISSING[@]}"; do echo "  - $M"; done
  echo "A rule that stays quiet on a file written to violate it, in a scope it"
  echo "declares, is a rule that is not running there. Each rule carries its"
  echo "own enforced_paths, so check that rule's block specifically -- and"
  echo "check the glob's spelling, since a glob that matches nothing is"
  echo "indistinguishable from a scope with no findings."
  echo "--- custom_lint said ---"
  echo "$OUT"
  exit 1
fi

# THE EVIDENCE, IN THE CI LOG. Printing only "OK" made a passing run
# unreviewable: nothing recorded WHICH rules fired, so a control that had
# silently narrowed to one rule -- or, later, to one directory -- looked
# exactly like one covering all of them.
PAIR_COUNT="$(echo "$PAIRS" | grep -c .)"
echo "lint gate assert: OK -- custom_lint exited $STATUS and all"
echo "$PAIR_COUNT (rule, scope) pair(s) across ${#PROBES[@]} probe(s) reported:$MATCHED"
exit 0
