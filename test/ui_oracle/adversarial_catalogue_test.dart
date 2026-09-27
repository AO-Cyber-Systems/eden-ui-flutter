// WHAT `expectUiSane` CATCHES, AND WHAT IT DOES NOT.
//
// The oracle's own self-test (`test/testing/expect_ui_sane_test.dart`) proves
// each RULE works: one fixture per rule, each asserting the rule names its
// defect. This file measures something the self-test structurally cannot —
// the ENUMERATION. Every one of the fourteen oracle defects found on this
// branch was found by someone breaking something ad hoc and noticing, and
// `AbsorbPointer` sat one line from the `IgnorePointer` fixture and defeated
// the same check. A rule that works is not the same fact as a rule that
// covers every widget producing its defect.
//
// So this file holds a CATALOGUE: one row per defect SHAPE, each row saying
// which check (if any) reports it, and each row proved by a run.
//
// THE THREE THINGS IT FAILS ON
//
//   1. A check in `expectUiSane` with NO row — a violation the oracle can
//      emit that nothing in this repo exercises.
//   2. A row naming a check that no longer exists — a fixture guarding a
//      rule that has been deleted or reworded out from under it.
//   3. A row whose measured status has CHANGED: a `caught` row that stopped
//      being caught (a regression), or a `notCaught` row that started being
//      caught (a gap someone closed — promote the row).
//
// The check list is DERIVED FROM THE ORACLE'S SOURCE, not typed out here:
// see `oracle_check_inventory.dart` for why a hand-maintained list is the
// exact drift shape this programme keeps being bitten by.
//
// A NOT-CAUGHT ROW IS NOT A BROKEN TEST. It is the most valuable output in
// the file: an executable statement of a blind spot, pinned so it turns red
// the day someone closes it. The assertion for such a row is deliberately
// two-sided — the oracle says nothing AND the frame is independently proved
// wrong — so it cannot go quiet because the fixture stopped being broken.
// Do NOT weaken a caught row to make a run green, and do NOT delete a
// not-caught row to make the table look better.
//
// PRE-FIX COLUMN. "Caught" alone cannot tell a reader whether a fixture would
// have found the original defect. Where an earlier shape of a rule is known,
// `legacy_oracle_rules.dart` keeps it executable and the row records what it
// answered — measured, not narrated.
library;

import 'dart:io';

import 'package:eden_ui_flutter/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_support/ui_oracle/_fixtures/adversarial_surfaces.dart';
import '../../test_support/ui_oracle/_fixtures/frame_probe.dart';
import '../../test_support/ui_oracle/_fixtures/legacy_oracle_rules.dart';
import '../../test_support/ui_oracle/_fixtures/oracle_check_inventory.dart';
import '../../test_support/ui_oracle/wrap.dart';

/// Where the generated coverage table is kept. Regenerate with
/// `UI_ORACLE_COVERAGE=write flutter test test/ui_oracle/adversarial_catalogue_test.dart`.
const String _tablePath = 'test_support/ui_oracle/_fixtures/ORACLE_COVERAGE.md';

/// The class of defect a row describes.
enum DefectClass {
  /// Visually present, functionally dead.
  unreachable,

  /// Present in the tree, illegible on the frame.
  unreadable,

  /// An error the framework swallowed during build, layout or paint.
  escaped,

  /// A shape that must produce NO violation. A false accusation is a defect
  /// in the oracle exactly as a missed one is.
  differential,
}

/// What a row's run showed.
enum RowStatus {
  /// A fixture in THIS lane, and the oracle names the defect.
  caught,

  /// The oracle names the defect, and the fixture that proves it lives in the
  /// review-findings lane (`broken_surfaces.dart`). Verified here by
  /// reference, not by a run: two lanes must not edit one fixture file.
  caughtElsewhere,

  /// A fixture in THIS lane, the surface is independently proved broken, and
  /// the oracle says nothing. A BLIND SPOT.
  notCaught,

  /// A check the oracle can emit that nothing exercises.
  noFixture,
}

/// An independent proof that a `notCaught` row's surface really is broken.
typedef FrameProof = Future<void> Function(WidgetTester tester);

/// One defect shape.
class CatalogueRow {
  const CatalogueRow({
    required this.shape,
    required this.defectClass,
    required this.status,
    required this.summary,
    this.fixture,
    this.identifier,
    this.checkId,
    this.messageContains,
    this.externalFixture,
    this.gap,
    this.legacyRoutesGt1,
    this.legacyOwnerInPath,
    this.proof,
    this.allowOverlap = const <(String, String)>{},
  });

  /// Stable handle for this shape. The fix lane can adopt these slugs; the
  /// nine oracle review findings have no canonical numbering in the repo, so
  /// pointing a row at "finding 3" would point it at a list that does not
  /// exist.
  final String shape;

  final DefectClass defectClass;
  final RowStatus status;

  /// One line a reader can decide from.
  final String summary;

  /// The fixture in `adversarial_surfaces.dart`, for rows this lane owns.
  final Widget Function()? fixture;

  /// The semantics identifier the violation must name.
  final String? identifier;

  /// The id of the check that reports this shape, as derived from the
  /// oracle's source. Null on a row nothing reports.
  final String? checkId;

  /// A fragment of the violation, asserted against the run AND against the
  /// derived check's message. Both sides must agree or the row is attached to
  /// the wrong check.
  final String? messageContains;

  /// `broken_surfaces.dart`'s fixture, for rows the other lane owns.
  final String? externalFixture;

  /// The blind spot this row belongs to, for `notCaught` and `noFixture`.
  final String? gap;

  /// What the PRE-lower-bound tap-route rule answered. Asserted when set.
  final bool? legacyRoutesGt1;

  /// What the PRE-rewrite reachability rule answered — true means "saw
  /// nothing wrong". Asserted when set.
  final bool? legacyOwnerInPath;

  /// The independent proof, required on every `notCaught` row.
  final FrameProof? proof;

  /// Overlap pairs this row's surface declares as deliberate.
  ///
  /// NOT AN ESCAPE HATCH FOR THE ROW — it is how a row about ONE defect keeps
  /// a SECOND, correct report from drowning it. A control nested inside
  /// another identified control overlaps it by construction, and
  /// `_overlapViolations` says so; a row whose subject is the nesting's
  /// effect on REACHABILITY has to exempt that pair or it can never assert
  /// "found 1 violation", let alone "found none". Per pair, like the rule
  /// itself: every other pair on the surface stays checked.
  final Set<(String, String)> allowOverlap;
}

// -----------------------------------------------------------------------------
// The blind spots
// -----------------------------------------------------------------------------

/// Gap slugs, defined here so the catalogue is self-contained and the fix
/// lane has somewhere to land a change.
const Map<String, String> gaps = <String, String>{
  'painted-ink-not-measured':
      'The contrast rule reads INK from the resolved TextStyle and only the '
          'BACKGROUND from the frame, so every defect that changes the ink at '
          'PAINT time is invisible to it: ShaderMask, ColorFiltered, and an '
          'opaque non-modal sibling painted over the paragraph. Candidate '
          'fix: after resolving the ink, require that some pixel inside the '
          "paragraph's box actually IS that ink. Not free — a 10px glyph in "
          'a real type family may have no full-coverage pixel, which is the '
          'same antialiasing problem that made the stock guideline unusable, '
          'so the test has to be coverage-weighted rather than exact.',
  'unresolvable-ink-is-silence':
      'A TextStyle.foreground carrying a SHADER leaves no colour to read, and '
          'the rule stays silent rather than accusing a control it did not '
          'measure. Recorded in the oracle as a known limit. Silence is the '
          'safe answer for a rule that cannot measure; it is the wrong answer '
          'for a reader who thinks a green run means the text is legible, '
          'which is why it is a row and not a footnote.',
  'text-rich-spans-unmeasured':
      'Text.rich has no `data`, so the walk skips it and a low-contrast span '
          'inside a rich paragraph is never measured. Recorded in the oracle '
          'as a known limit; fixtured here so the limit is executable.',
  'removed-control-out-of-contract':
      'A control collapsed to zero size, clipped entirely out, or placed '
          'behind Offstage publishes NO presented semantics node and paints '
          'NO pixels. There is nothing on the surface for a surface-level '
          'oracle to measure, and expectUiSane takes no list of what SHOULD '
          'be there. These are catchable only against a declared expectation '
          '— the story manifest or the golden diff — and naming them here is '
          'the point: a green expectUiSane says nothing about whether the '
          'screen still has its buttons.',
  'a11y-route-is-not-a-finger':
      'A tap route declared with Semantics(onTap:) creates no pointer '
          'handler, and nothing in the render tree says which render object — '
          'if any — implements it. `_pointerReaches` can therefore only '
          'observe whether SOMETHING inside the control took the hit, never '
          'whether a finger would take the ROUTE. Measured: the lane\'s own '
          'differential control, `_liveButton`, is pointer-inert — '
          'tester.tapAt at its centre does not fire its onTap — and passes. '
          'A rule that tried to close this by asking WHAT took the hit was '
          'reverted in round 3: it falsely accused an all-live row with an '
          'identified child at its centre (Stack hit-tests lastChild first, '
          'so the child takes the centre and the row\'s own live surface is '
          'never in the path) and still missed the bare-Text shape. Closing '
          'it honestly means deciding whether an accessibility-only tap route '
          'is a defect at all — a product decision with a wide blast radius, '
          'since the clean fixture and every unreachable row are built on '
          'that shape — not a smarter hit-test walk.',
  'guideline-exception-unfixturable':
      'The drain that re-reports an exception raised while the stock '
          'accessibility guidelines run. Provoking it in-process means '
          'breaking the font bootstrap or the guideline machinery for the '
          'whole file, which would make every other test in it meaningless. '
          'Left with no fixture DELIBERATELY, and named here so the table '
          'does not imply coverage it does not have.',
};

/// Shapes the review-findings lane owns. Fixtured in `broken_surfaces.dart`,
/// declared here so the table is complete and the two lanes do not edit one
/// fixture file. The slugs are minted here: there is no canonical numbering
/// of the nine findings in this repo.
const Map<String, String> ownedByFixLane = <String, String>{
  'absorb-pointer-path':
      'AbsorbPointer returns a hit WITHOUT adding itself or anything below '
          'it to the path, so the enclosing annotation adds itself and the '
          'owner is in the path on a control no finger can touch.',
  'ink-equals-background':
      'Every pixel inside the box is the ink: 1.00:1, invisible text, '
          'reported as the maximum-severity 1.4.3 failure rather than as an '
          'unmeasurable region.',
  'opacity-faded-ink':
      'Ancestor Opacity/AnimatedOpacity/FadeTransition factors composed into '
          "the ink's alpha, so a faded caption is measured as painted rather "
          'than as authored.',
  'inkwell-unflagged-tap':
      'InkWell publishes Semantics(onTap:) with no button flag; reachability '
          'is asserted for every identified node that declares a tap route, '
          'flagged or not.',
  'hidden-node-viewport':
      "A ListView's off-screen rows publish real identifiers and real tap "
          'routes. Excluding non-presented nodes is what stops a correct '
          '30-row list reporting one false accusation per off-screen row.',
};

// -----------------------------------------------------------------------------
// The catalogue
// -----------------------------------------------------------------------------

final List<CatalogueRow> catalogue = <CatalogueRow>[
  // ---- differential control -------------------------------------------------
  const CatalogueRow(
    shape: 'live-control',
    defectClass: DefectClass.differential,
    status: RowStatus.caught,
    summary: 'The button every UNREACHABLE fixture wraps, with no mechanism '
        'around it. If this reports anything, every row below is measuring '
        'the harness rather than the mechanism it names.',
    fixture: liveControlSurface,
    identifier: 'adv-control',
    legacyRoutesGt1: false,
    legacyOwnerInPath: true,
  ),

  // ---- UNREACHABLE, caught here --------------------------------------------
  const CatalogueRow(
    shape: 'stack-child-outside-unclipped-parent',
    defectClass: DefectClass.unreachable,
    status: RowStatus.caught,
    summary: 'Positioned outside a Stack with clipBehavior: Clip.none. It '
        'paints, it publishes an unclipped rect, and RenderBox.hitTest on '
        'the parent rejects every position its own size does not contain.',
    fixture: overflowingStackChild,
    identifier: 'adv-stack-overflow',
    checkId: '_tapRouteViolations#control-announces-itself-as-and-declares',
    messageContains: 'and declares a tap action, but a pointer dropped',
    legacyRoutesGt1: false,
    legacyOwnerInPath: false,
  ),
  const CatalogueRow(
    shape: 'transform-that-does-not-move-the-hit-test',
    defectClass: DefectClass.unreachable,
    status: RowStatus.caught,
    summary: 'Transform.translate(transformHitTests: false). The semantics '
        'rect follows the PAINT and the hit test runs at the untransformed '
        'position, so the node is published exactly where the pointer is not.',
    fixture: transformHitTestsDetached,
    identifier: 'adv-transform-hit',
    checkId: '_tapRouteViolations#control-announces-itself-as-and-declares',
    messageContains: 'and declares a tap action, but a pointer dropped',
    legacyRoutesGt1: false,
    legacyOwnerInPath: false,
  ),
  const CatalogueRow(
    shape: 'covered-by-a-later-sibling',
    defectClass: DefectClass.unreachable,
    status: RowStatus.caught,
    summary: 'A translucent ColoredBox later in the Stack. The control is '
        'visible through it and takes no pointer: ColoredBox hit-tests '
        'opaque. No two identified rects intersect, so the overlap rule has '
        'nothing to say.',
    fixture: coveredByLaterSibling,
    identifier: 'adv-covered',
    checkId: '_tapRouteViolations#control-announces-itself-as-and-declares',
    messageContains: 'and declares a tap action, but a pointer dropped',
    legacyRoutesGt1: false,
    legacyOwnerInPath: false,
  ),
  const CatalogueRow(
    shape: 'no-hit-surface-under-the-node',
    defectClass: DefectClass.unreachable,
    status: RowStatus.caught,
    summary: 'A fully sized Semantics(onTap:) over an empty SizedBox. '
        'Nothing beneath the owner hit-tests at all, so no pointer can ever '
        'take the route the node advertises.',
    fixture: emptyHitSurfaceControl,
    identifier: 'adv-empty-hit',
    checkId: '_tapRouteViolations#control-announces-itself-as-and-declares',
    messageContains: 'and declares a tap action, but a pointer dropped',
    legacyRoutesGt1: false,
    legacyOwnerInPath: false,
  ),
  const CatalogueRow(
    shape: 'visibility-maintaining-size-and-semantics',
    defectClass: DefectClass.unreachable,
    status: RowStatus.caught,
    summary: 'Visibility(visible: false) keeping size, state and SEMANTICS '
        'and dropping interactivity. The node keeps its rect, its label and '
        'its button flag; the IgnorePointer it wraps the subtree in strips '
        'the tap route, so the oracle reports it through the ZERO arm.',
    fixture: maintainedInvisibleControl,
    identifier: 'adv-maintained',
    checkId: '_tapRouteViolations#control-announces-itself-as-but-has',
    messageContains: 'but has no tap action',
    legacyRoutesGt1: false,
    legacyOwnerInPath: false,
  ),
  const CatalogueRow(
    shape: 'transformed-past-the-view-edge',
    defectClass: DefectClass.unreachable,
    status: RowStatus.caught,
    summary: 'Transform.translate pushing a control past the right edge. The '
        'pointer path is honest here — the transform moves the hit test too — '
        'and the defect is containment, not reachability.',
    fixture: transformedOutOfViewport,
    identifier: 'adv-offscreen',
    checkId: '_viewportViolations#control-is-outside-the-viewport-its',
    messageContains: 'is outside the viewport',
    legacyRoutesGt1: false,
    legacyOwnerInPath: true,
  ),

  // ---- ESCAPED, caught here -------------------------------------------------
  const CatalogueRow(
    shape: 'exception-swallowed-during-build',
    defectClass: DefectClass.escaped,
    status: RowStatus.caught,
    summary: 'The GENERIC arm of the escaped-exception report. The overflow '
        'arm has a fixture; every other error a screen can hit in production '
        'goes down this one and had none.',
    fixture: throwingBuild,
    checkId: '_describeEscapedException#an-exception-escaped-during-layout-paint',
    messageContains: 'an exception escaped during layout/paint',
  ),

  // ---- UNREADABLE, NOT caught ----------------------------------------------
  CatalogueRow(
    shape: 'shader-mask-repaints-the-ink',
    defectClass: DefectClass.unreadable,
    status: RowStatus.notCaught,
    summary: 'ShaderMask fills every glyph with the background colour. The '
        'resolved style says 18.9:1; the frame is one flat colour.',
    fixture: shaderMaskedText,
    gap: 'painted-ink-not-measured',
    proof: _provesNoInkReachesTheFrame('Payment overdue', advSurface),
  ),
  CatalogueRow(
    shape: 'color-filter-repaints-the-ink',
    defectClass: DefectClass.unreadable,
    status: RowStatus.notCaught,
    summary: 'ColorFiltered(srcIn) does the same through the widget a theming '
        'layer is most likely to reach for.',
    fixture: colorFilteredText,
    gap: 'painted-ink-not-measured',
    proof: _provesNoInkReachesTheFrame('Balance 4200', advSurface),
  ),
  CatalogueRow(
    shape: 'text-under-an-opaque-non-modal-sibling',
    defectClass: DefectClass.unreadable,
    status: RowStatus.notCaught,
    summary: 'An opaque cover painted over the paragraph. The measured '
        "background IS the cover, so the rule compares the author's ink to a "
        'surface the glyphs never reached.',
    fixture: textUnderOpaqueSibling,
    gap: 'painted-ink-not-measured',
    proof: _provesNoInkReachesTheFrame('Payment failed', advOpaqueCover),
  ),
  CatalogueRow(
    shape: 'glyphs-clipped-out-of-their-own-box',
    defectClass: DefectClass.unreadable,
    status: RowStatus.notCaught,
    summary: 'A 20px paragraph in a 6px slot. The visible band lands entirely '
        "in the line's ascent, so not one glyph pixel reaches the frame while "
        'the style and the measured background both read as conformant.',
    fixture: clippedGlyphsText,
    gap: 'painted-ink-not-measured',
    proof: _provesNoInkReachesTheFrame('Overdue notice', advSurface),
  ),
  CatalogueRow(
    shape: 'foreground-paint-carrying-a-shader',
    defectClass: DefectClass.unreadable,
    status: RowStatus.notCaught,
    summary: 'TextStyle.foreground nulls out `color`, and a paint carrying a '
        'shader has no colour to read, so the rule cannot resolve an ink and '
        'stays silent. The SOLID half of this shape is resolved correctly.',
    fixture: shaderForegroundText,
    gap: 'unresolvable-ink-is-silence',
    proof: _provesNoInkReachesTheFrame('Amount due', advSurface),
  ),
  const CatalogueRow(
    shape: 'low-contrast-span-in-a-rich-paragraph',
    defectClass: DefectClass.unreadable,
    status: RowStatus.notCaught,
    summary: 'Text.rich carries no `data`, so the paragraph is skipped whole '
        'and a 1.06:1 span inside it is never measured.',
    fixture: lowContrastRichSpan,
    gap: 'text-rich-spans-unmeasured',
    proof: _provesSpanIsOnTheFrameAndIllegible,
  ),

  CatalogueRow(
    shape: 'repaired-bare-text-row',
    defectClass: DefectClass.differential,
    status: RowStatus.caught,
    summary: 'THE POSITIVE CONTROL for the tap proof, and the executed form '
        'of the repair claim on deadRouteBareText: the same tree with the '
        "row's own surface moved ON TOP of the Text. The oracle says "
        'nothing AND a real tap fires the callback.',
    fixture: repairedBareTextRow,
    identifier: 'adv-repaired-row',
    proof: _provesTapFires('adv-repaired-row'),
  ),

  // ---- UNREACHABLE, NOT caught: the hit test cannot decide -----------------
  CatalogueRow(
    shape: 'dead-route-live-inner-control',
    defectClass: DefectClass.unreachable,
    status: RowStatus.notCaught,
    summary: "The row's own tap surface is inside an IgnorePointer and a live "
        'switch sits under its centre. Stack hit-tests lastChild first, so '
        'the switch takes the hit, something inside the owner IS in the path, '
        'and the row reads reachable.',
    fixture: deadRouteLiveInnerControl,
    gap: 'a11y-route-is-not-a-finger',
    proof: _provesTapDoesNotFire('adv-dead-route-row'),
    // The nesting is reported — correctly — by the OVERLAP rule, which is a
    // different defect and a different message. Exempting that one pair is
    // what lets this row be about reachability at all.
    allowOverlap: const <(String, String)>{
      ('adv-dead-route-row', 'adv-dead-route-switch'),
    },
  ),
  CatalogueRow(
    shape: 'dead-route-bare-text-at-the-centre',
    defectClass: DefectClass.unreachable,
    status: RowStatus.notCaught,
    summary: 'The same dead row with a bare Text under the centre. '
        'RenderParagraph hit-tests itself, carries no identifier and '
        'advertises no tap — the shape that defeats every "what took the '
        'hit?" refinement while keeping the route count at 1.',
    fixture: deadRouteBareText,
    gap: 'a11y-route-is-not-a-finger',
    proof: _provesTapDoesNotFire('adv-dead-route-text'),
  ),
  CatalogueRow(
    shape: 'accessibility-only-tap-route',
    defectClass: DefectClass.unreachable,
    status: RowStatus.notCaught,
    summary: "THE LANE'S OWN BASELINE. Semantics(button: true, onTap:) over a "
        'Text, with no gesture handler anywhere — the shape of _liveButton, '
        'which this file calls "genuinely live". A real tap does not fire '
        'its onTap, and the oracle says nothing.',
    fixture: accessibilityOnlyTapRoute,
    gap: 'a11y-route-is-not-a-finger',
    proof: _provesTapDoesNotFire('adv-a11y-only-route'),
  ),

  // ---- UNREACHABLE by removal, NOT caught ----------------------------------
  CatalogueRow(
    shape: 'zero-size-ancestor',
    defectClass: DefectClass.unreachable,
    status: RowStatus.notCaught,
    summary: 'SizedBox.shrink collapses the control to 0x0. It publishes no '
        'presented node and paints no pixel, so there is nothing on the '
        'surface to measure.',
    fixture: zeroSizeAncestorControl,
    gap: 'removed-control-out-of-contract',
    proof: _provesControlVanished('adv-zero-size'),
  ),
  CatalogueRow(
    shape: 'clipped-entirely-out-by-an-ancestor',
    defectClass: DefectClass.unreachable,
    status: RowStatus.notCaught,
    summary: 'A ClipRect the control lies wholly outside. Semantics '
        'compilation intersects the rect with the ancestor clip and the node '
        'stops being presented.',
    fixture: clippedOutControl,
    gap: 'removed-control-out-of-contract',
    proof: _provesControlVanished('adv-clipped-out'),
  ),
  CatalogueRow(
    shape: 'offstage',
    defectClass: DefectClass.unreachable,
    status: RowStatus.notCaught,
    summary: 'Offstage removes the control from layout, paint and semantics '
        'alike. Included for completeness and because its silence is the '
        'clearest statement of the contract: nothing is present, so nothing '
        'is measured.',
    fixture: offstageControl,
    gap: 'removed-control-out-of-contract',
    proof: _provesControlVanished('adv-offstage'),
  ),

  // ---- checks fixtured in the review-findings lane -------------------------
  const CatalogueRow(
    shape: 'render-overflow',
    defectClass: DefectClass.escaped,
    status: RowStatus.caughtElsewhere,
    summary: 'A RenderFlex overflow, re-reported with the creator chain the '
        'informationCollector would otherwise have thrown away.',
    checkId: '_describeEscapedException#overflow-of-pixels-on-the-offending',
    messageContains: 'overflow of',
    externalFixture: 'overflowingRow',
  ),
  const CatalogueRow(
    shape: 'stock-guideline-failure',
    defectClass: DefectClass.unreachable,
    status: RowStatus.caughtElsewhere,
    summary: "flutter_test's own tap-target and labelling guidelines, folded "
        'into the aggregated report.',
    checkId: '_guidelineViolations#site-0',
    externalFixture: 'tinyTapTarget',
  ),
  const CatalogueRow(
    shape: 'overlapping-identified-controls',
    defectClass: DefectClass.unreachable,
    status: RowStatus.caughtElsewhere,
    summary: 'On web the semantics node is the click target, so an overlap '
        "means one control eats the other's taps.",
    checkId: '_overlapViolations#controls-and-overlap-is-is-they',
    messageContains: 'overlap:',
    externalFixture: 'overlappingControls',
  ),
  const CatalogueRow(
    shape: 'two-tap-routes-on-one-control',
    defectClass: DefectClass.unreachable,
    status: RowStatus.caughtElsewhere,
    summary: 'A tap fires every route the node and its unidentified '
        'descendants advertise.',
    checkId: '_tapRouteViolations#control-declares-tap-actions-its-own',
    messageContains: 'tap actions (its own semantics node',
    externalFixture: 'doubleTapAction',
  ),
  const CatalogueRow(
    shape: 'absorb-pointer-path',
    defectClass: DefectClass.unreachable,
    status: RowStatus.caughtElsewhere,
    summary: 'See the ownedByFixLane entry. Not fixtured here: the fix lane '
        'owns it.',
    checkId: '_tapRouteViolations#control-announces-itself-as-and-declares',
    externalFixture: 'absorbedButton',
  ),
  const CatalogueRow(
    shape: 'inkwell-unflagged-tap',
    defectClass: DefectClass.unreachable,
    status: RowStatus.caughtElsewhere,
    summary: 'See the ownedByFixLane entry. Not fixtured here: the fix lane '
        'owns it.',
    checkId: '_tapRouteViolations#control-declares-a-tap-action-but',
    externalFixture: 'unreachableUnflaggedControl',
  ),
  const CatalogueRow(
    shape: 'ink-equals-background',
    defectClass: DefectClass.unreadable,
    status: RowStatus.caughtElsewhere,
    summary: 'See the ownedByFixLane entry. Not fixtured here: the fix lane '
        'owns it.',
    checkId: '_measureText#painted-text-is-1-00-1',
    externalFixture: 'invisibleText',
  ),
  const CatalogueRow(
    shape: 'opacity-faded-ink',
    defectClass: DefectClass.unreadable,
    status: RowStatus.caughtElsewhere,
    summary: 'See the ownedByFixLane entry. Not fixtured here: the fix lane '
        'owns it.',
    checkId: '_measureText#painted-text-is-1-against-its',
    externalFixture: 'fadedText',
  ),
  const CatalogueRow(
    shape: 'low-contrast-text',
    defectClass: DefectClass.unreadable,
    status: RowStatus.caughtElsewhere,
    summary: 'The plain 1.4.3 failure: resolved ink against measured '
        'background, below the floor for its size and weight.',
    checkId: '_measureText#painted-text-is-1-against-its',
    messageContains: 'below the WCAG 1.4.3 floor',
    externalFixture: 'darkOnDark',
  ),
  const CatalogueRow(
    shape: 'hidden-node-viewport',
    defectClass: DefectClass.differential,
    status: RowStatus.caughtElsewhere,
    summary: 'See the ownedByFixLane entry. A false accusation is a defect in '
        'the oracle exactly as a missed one is; this row is the guard against '
        'the viewport rule producing one.',
    checkId: '_viewportViolations#control-is-outside-the-viewport-its',
    externalFixture: 'scrolledListRows',
  ),

  // ---- a check nothing exercises -------------------------------------------
  const CatalogueRow(
    shape: 'exception-raised-while-guidelines-run',
    defectClass: DefectClass.escaped,
    status: RowStatus.noFixture,
    summary: 'The drain that re-reports anything the guideline phase routed '
        'through the pending-exception channel. NOTHING exercises it.',
    checkId:
        '_guidelineViolations#an-exception-escaped-while-evaluating-accessibility',
    gap: 'guideline-exception-unfixturable',
  ),
];

// -----------------------------------------------------------------------------
// Independent proofs
// -----------------------------------------------------------------------------

/// Proves the paragraph carrying [text] contributes NO pixel of its declared
/// ink to the frame, and that its whole box reads as [expected].
///
/// This is what makes a not-caught row two-sided. Without it the row asserts
/// only that `expectUiSane` was quiet, which is also what a fixture that
/// stopped being broken would assert.
FrameProof _provesNoInkReachesTheFrame(String text, Color expected) {
  return (WidgetTester tester) async {
    final Finder finder = find.text(text);
    expect(finder, findsOneWidget, reason: 'the fixture stopped painting it');
    final Map<int, int> histogram = await frameHistogramOf(tester, finder);
    expect(
      histogram,
      isNotEmpty,
      reason: 'no pixels were captured for "$text" — the proof measured '
          'nothing and the row below would be vacuous',
    );
    expect(
      pixelsNear(histogram, advLegibleInk, tolerance: 24),
      0,
      reason: 'the fixture is supposed to keep every glyph of "$text" off the '
          'frame; ink pixels means it is no longer demonstrating the blind '
          'spot',
    );
    expect(
      histogram.length,
      1,
      reason: '"$text" should render as one flat colour',
    );
    expect(dominantColour(histogram)!.toARGB32(), expected.toARGB32());
  };
}

/// Proves the pale span in `lowContrastRichSpan` really is painted, and
/// really is below the WCAG floor against the surface it is painted on.
///
/// The other rich-span half — that the oracle never measures it — is the
/// row's own no-violation assertion.
Future<void> _provesSpanIsOnTheFrameAndIllegible(WidgetTester tester) async {
  final Map<int, int> histogram =
      await frameHistogramOf(tester, find.byType(Text));
  expect(
    pixelsNear(histogram, advRichSpanInk, tolerance: 1),
    greaterThan(0),
    reason: 'the pale span is not on the frame, so there is nothing to miss',
  );
  expect(
    pixelsNear(histogram, advLegibleInk, tolerance: 24),
    greaterThan(0),
    reason: 'the legible span is not on the frame either — the fixture is not '
        'rendering',
  );
  expect(
    contrastRatio(advRichSpanInk, advSurface),
    lessThan(4.5),
    reason: 'the span colour is no longer a 1.4.3 failure, so this row is not '
        'demonstrating anything',
  );
}

/// Proves that a REAL TAP at the centre of [identifier]'s published rect does
/// not fire the control's own callback.
///
/// THIS IS A STRONGER PROOF THAN THE FRAME READINGS ABOVE, and it has to be:
/// the defect these rows describe is not visible on the frame at all. The
/// control paints correctly, publishes a correct rect, announces a button and
/// declares a route. The only thing wrong with it is that pressing it does
/// nothing, and the only instrument that can see that is a press.
///
/// It also pins the PREMISE both ways: the rect has to exist and the tap has
/// to land inside it, or a row could go quiet because the fixture stopped
/// rendering rather than because the oracle stopped reporting.
FrameProof _provesTapDoesNotFire(String identifier) {
  return (WidgetTester tester) async {
    final Rect rect = globalRectOf(tester, identifier);
    final double ratio = tester.view.devicePixelRatio;
    final Offset centre = rect.center / ratio;
    expect(
      advTapFired,
      isFalse,
      reason: 'the fixture reported a tap before this proof pressed '
          'anything — the flag is not being reset',
    );

    await tester.tapAt(centre);
    await tester.pump();

    expect(
      advTapFired,
      isFalse,
      reason: '"$identifier" IS reachable by a real tap now. Either the '
          'fixture stopped demonstrating the defect, or the oracle has '
          'learned to report this class and the row should be promoted to '
          'caught — establish WHICH before touching this row.',
    );
  };
}

/// THE POSITIVE CONTROL for [_provesTapDoesNotFire]: proves a real tap at the
/// centre of [identifier]'s rect DOES fire the control's callback.
///
/// Without this, the negative proof is unfalsifiable. `advTapFired` is wired
/// in every other fixture to an `onTap` no pointer can reach, so "false after
/// the tap" is also what a never-reset flag, a fixture that stopped
/// rendering, and an `onTap: () {}` typo all produce. This is the case that
/// fails when the flag stops working, instead of every other case passing
/// more easily.
FrameProof _provesTapFires(String identifier) {
  return (WidgetTester tester) async {
    final Rect rect = globalRectOf(tester, identifier);
    expect(advTapFired, isFalse, reason: 'the flag was not reset');

    await tester.tapAt(rect.center / tester.view.devicePixelRatio);
    await tester.pump();

    expect(
      advTapFired,
      isTrue,
      reason: 'a real tap in the middle of "$identifier" did NOT fire its '
          'callback. Either this fixture has stopped being the repaired '
          'shape, or advTapFired has stopped working — and if it has, every '
          'row that reads it as FALSE is now passing for no reason.',
    );
  };
}

/// Proves the control carrying [identifier] has left the surface entirely —
/// no presented semantics node — which is why the oracle has nothing to say.
FrameProof _provesControlVanished(String identifier) {
  return (WidgetTester tester) async {
    final List<String?> present = identifiedNodes(tester)
        .map((SemanticsGeometryNode node) => node.identifier)
        .toList();
    expect(
      present,
      isNot(contains(identifier)),
      reason: '"$identifier" IS presented now. If the control came back, the '
          'fixture is no longer demonstrating a removed control; if the '
          'oracle started presenting removed controls, this row has become a '
          'caught one and should be promoted.',
    );
  };
}

// -----------------------------------------------------------------------------
// The run
// -----------------------------------------------------------------------------

Future<TestFailure?> _runOracle(
  WidgetTester tester, {
  Set<(String, String)> allowOverlap = const <(String, String)>{},
}) async {
  try {
    await expectUiSane(tester, allowOverlap: allowOverlap);
    return null;
  } on TestFailure catch (failure) {
    return failure;
  }
}

void main() {
  final OracleCheckInventory inventory = readOracleCheckInventory();

  group('catalogue rows', () {
    for (final CatalogueRow row in catalogue) {
      if (row.fixture == null) {
        continue;
      }
      testWidgets('${row.shape} (${row.status.name})',
          (WidgetTester tester) async {
        await wrap(tester, row.fixture!());
        final TestFailure? failure =
            await _runOracle(tester, allowOverlap: row.allowOverlap);

        switch (row.status) {
          case RowStatus.caught:
            if (row.checkId == null) {
              expect(
                failure,
                isNull,
                reason: 'the differential control must pass: '
                    '${failure?.message}',
              );
            } else {
              expect(
                failure,
                isNotNull,
                reason: 'REGRESSION: the oracle no longer reports '
                    '"${row.shape}". Either a check was narrowed or the '
                    'fixture stopped being broken — do not flip this row to '
                    'notCaught without establishing which.',
              );
              expect(
                failure!.message,
                contains('found 1 violation(s)'),
                reason: 'a catalogue fixture must break exactly one thing, or '
                    'the row does not prove which check reported it',
              );
              expect(failure.message, contains(row.messageContains!));
              if (row.identifier != null) {
                expect(failure.message, contains('"${row.identifier}"'));
              }
            }
          case RowStatus.notCaught:
            expect(
              failure,
              isNull,
              reason: 'GAP CLOSED: the oracle now reports "${row.shape}". '
                  'Promote this row to caught, give it a checkId and a '
                  'messageContains, and take its gap out of the table. '
                  'Reported: ${failure?.message}',
            );
          case RowStatus.caughtElsewhere:
          case RowStatus.noFixture:
            fail('a row with a fixture cannot be ${row.status.name}');
        }

        // EVERY row that declares a proof runs it, not only the notCaught
        // ones. A `caught` differential row is exactly where the POSITIVE
        // control for a proof instrument belongs: it is the case that fails
        // when the instrument stops working.
        if (row.proof != null) {
          await row.proof!(tester);
        }

        if (row.legacyRoutesGt1 != null) {
          expect(
            legacyRoutesGreaterThanOne(tester, row.identifier!),
            row.legacyRoutesGt1,
            reason: 'the pre-lower-bound rule changed its answer for '
                '"${row.shape}"; the table\'s pre-fix column is now wrong',
          );
        }
        if (row.legacyOwnerInPath != null) {
          expect(
            legacyOwnerAnywhereInPath(tester, row.identifier!),
            row.legacyOwnerInPath,
            reason: 'the pre-rewrite reachability rule changed its answer for '
                '"${row.shape}"; the table\'s pre-fix column is now wrong',
          );
        }
      });
    }
  });

  group('coverage', () {
    test('every check the oracle can emit has a row', () {
      final Set<String> claimed = <String>{
        for (final CatalogueRow row in catalogue)
          if (row.checkId != null) row.checkId!,
      };
      final List<String> orphans = <String>[
        for (final OracleCheckSite site in inventory.sites)
          if (!claimed.contains(site.id)) '${site.id}\n      ${site.message}',
      ];
      expect(
        orphans,
        isEmpty,
        reason: 'expectUiSane can emit a violation that no catalogue row '
            'accounts for. Add a row — a fixture if the shape can be built, '
            'a noFixture row naming why not if it cannot. Unaccounted:\n'
            '${orphans.join('\n')}',
      );
    });

    test('every row points at a check that still exists', () {
      for (final CatalogueRow row in catalogue) {
        if (row.checkId == null) {
          // A differential row asserts the ABSENCE of a violation, so it
          // names no check by construction and owns no gap: the shape is not
          // a defect, and a rule reporting it would be the defect.
          if (row.defectClass == DefectClass.differential) {
            expect(
              row.status,
              RowStatus.caught,
              reason: 'a differential row with no check must pass',
            );
            continue;
          }
          expect(
            row.gap,
            isNotNull,
            reason: '"${row.shape}" names no check and declares no gap. A row '
                'that reports nothing and owns nothing is a fixture with '
                'nothing behind it.',
          );
          expect(gaps, contains(row.gap), reason: 'undefined gap "${row.gap}"');
          continue;
        }
        expect(
          inventory[row.checkId!],
          isNotNull,
          reason: '"${row.shape}" points at check "${row.checkId}", which the '
              'oracle no longer emits. Either the check was deleted — delete '
              'the row with it — or its message was reworded, in which case '
              'the row has to follow. Emitted now:\n'
              '${inventory.sites.map((OracleCheckSite s) => '  ${s.id}').join('\n')}',
        );
      }
    });

    test('each asserted fragment belongs to the check its row names', () {
      for (final CatalogueRow row in catalogue) {
        if (row.checkId == null || row.messageContains == null) {
          continue;
        }
        expect(
          inventory[row.checkId!]!.message,
          contains(row.messageContains!),
          reason: '"${row.shape}" asserts a fragment that does not appear in '
              'the message of the check it names. The row is attached to the '
              'wrong check, or the fragment spans an interpolation.',
        );
      }
    });

    test('the message fragments no site attributes are the known one', () {
      // THE OTHER DIRECTION, and the one that makes "every check has a row"
      // worth anything.
      //
      // "Every check has a row" only ever looked at checks the PARSER
      // recognised. A site the parser could not see produced no inventory
      // row, so there was no orphan to report and this table passed — with a
      // check nothing in the repo exercises. It could not see a
      // double-quoted message, an arrow body, or a message built into a
      // local, and the floor it was measured against (12 sites against a
      // minimum of 10) had two sites of slack on top of that.
      //
      // So the inventory now reports every message-shaped literal inside a
      // reachable function that no recognised site claims, and this pins the
      // list BY NAME rather than at a count. An unrecognised message site
      // fails here instead of being ignored.
      //
      // THE TWO ENTRIES.
      //
      //   * `_describeEscapedException` builds the "Offending widget(s):"
      //     tail of the overflow message through a ternary into a local, so
      //     the empty-culprits branch is a fragment no opener can be sitting
      //     behind. It belongs to
      //     `_describeEscapedException#overflow-of-pixels-on-the-offending`,
      //     which the `render-overflow` row accounts for.
      //   * `expectUiSane`'s own aggregation HEADER. It is not a check — it
      //     is the envelope every check's message is printed inside, and it
      //     appears here only because `expectUiSane`'s body is now scanned
      //     at all, which is the point of that change.
      expect(
        inventory.unattributedLiterals,
        <String>[
          '_describeEscapedException: the overflowing render object could '
              'not be located in the tree',
          'expectUiSane: expectUiSane found * violation(s) on this surface:',
        ],
        reason: 'a message-shaped string in expect_ui_sane.dart is not '
            'accounted for by any recognised check site. Either it IS a '
            'violation message written in a shape '
            'oracle_check_inventory.dart does not parse — fix the parser and '
            'give the check a row — or it is a fragment of a message that '
            'already has one, in which case add it here WITH the reason. '
            'Found:\n  ${inventory.unattributedLiterals.join('\n  ')}',
      );
    });

    test('returned fragments rejected by the length floor are the known six',
        () {
      // Each of these is a PHRASE substituted into somebody else's message,
      // not a violation:
      //
      //   ''    — `_stringOf`'s switch default: a widget that paints no
      //           string at all.
      //   '#*'  — `_hex`, which formats a colour for another message.
      //   '*'   — TWICE: `_describeEscapedException`'s per-culprit
      //           separator `'\n      $c'`, and `expectUiSane`'s own
      //           `'  - $v'` bullet, both normalised to the interpolation.
      //   'a button' / 'a link' — `_announcedAffordance`, the noun phrase the
      //           tap-route messages interpolate.
      expect(
        inventory.rejectedFragments,
        <String>['', '#*', '*', '*', 'a button', 'a link'],
        reason: 'a short returned literal appeared in a reachable check '
            'function. If it is a phrase substituted into another message, '
            'add it here. If it is a VIOLATION message, the length floor in '
            'oracle_check_inventory.dart is now hiding a check from this '
            'table.',
      );
    });

    test('rows owned by the fix lane point at fixtures that exist', () {
      const String path = 'test/testing/_fixtures/broken_surfaces.dart';
      final String source = File(path).readAsStringSync();
      for (final CatalogueRow row in catalogue) {
        if (row.externalFixture == null) {
          continue;
        }
        expect(
          source,
          contains('Widget ${row.externalFixture}('),
          reason: '"${row.shape}" points at $path#${row.externalFixture}, '
              'which is not there any more. The fixture was renamed or '
              'removed; update this row rather than deleting the assertion.',
        );
      }
    });

    test('every shape slug is unique', () {
      final List<String> slugs =
          catalogue.map((CatalogueRow row) => row.shape).toList();
      expect(slugs.toSet().length, slugs.length);
    });
  });

  group('the inventory parser', () {
    // DIFFERENTIAL CONTROL for the derivation itself. If the regexes silently
    // stopped matching, `readOracleCheckInventory` would return an empty list
    // and every coverage assertion above would pass on nothing. These run the
    // parser against a source it is not reading in anger, so a change that
    // breaks the extraction is named here rather than showing up as a table
    // that quietly shrank.
    //
    // The fake carries one of each SHAPE a message can be written in —
    // single-quoted, double-quoted, arrow-bodied — because the parser used to
    // see only the first and the catalogue had no way to notice.
    const String fake = '''
Future<void> expectUiSane(WidgetTester tester) async {
  final List<String> violations = <String>[];
  violations.addAll(_fakeCheck(tester));
  violations.add(_fakeDescribe(tester));
  violations.add(_fakeArrow(tester));
}

List<String> _fakeCheck(WidgetTester tester) {
  final List<String> out = <String>[];
  out.add('control "\$id" did the wrong thing entirely');
  out.add("a double-quoted message is still a message");
  out.add('\${a}: \${b}');
  return out;
}

String _fakeDescribe(WidgetTester tester) {
  if (tester == null) {
    return 'a phrase';
  }
  return 'a message long enough to be a violation';
}

String _fakeArrow(WidgetTester tester) =>
    'an arrow body is a return written shorter';

String _notReachable() {
  return 'this one is never aggregated and must not appear';
}
''';

    test('finds add sites of any length, long returns and arrow bodies', () {
      final OracleCheckInventory inventory = parseOracleCheckInventory(fake);
      expect(
        inventory.sites.map((OracleCheckSite s) => s.message),
        unorderedEquals(<String>[
          'a message long enough to be a violation',
          'an arrow body is a return written shorter',
          'a double-quoted message is still a message',
          'control "*" did the wrong thing entirely',
          '*: *',
        ]),
        reason: 'the parser must keep a fully-interpolated add() site, both '
            'quote styles and an arrow body, and drop nothing but short '
            'returns',
      );
    });

    test('reports the short returns it rejected', () {
      expect(
        parseOracleCheckInventory(fake).rejectedFragments,
        <String>['a phrase'],
      );
    });

    test('never reaches a function expectUiSane does not aggregate', () {
      expect(
        parseOracleCheckInventory(fake).reachedFunctions,
        isNot(contains('_notReachable')),
      );
    });

    test('a recognised source leaves nothing unattributed', () {
      // The differential control for the case below. If the fake produced
      // unattributed literals of its own, that case would pass whatever the
      // reverse scan did.
      expect(parseOracleCheckInventory(fake).unattributedLiterals, isEmpty);
    });

    test('a message built into a LOCAL becomes a site, interpolation and all',
        () {
      // TWO HOLES, and the second is the one that could still lose a check.
      //
      // A message assembled into a local sits behind no `.add(`, no `return`
      // and no `=>`, so the opener scan cannot see it. A PROSE message was
      // still caught by the reverse scan. A message that is pure
      // INTERPOLATION was not: `'${a}: ${b}'` normalises to `*: *`, five
      // characters, under the message-shaped floor — so it produced no site,
      // no unattributed literal and no rejected fragment, and the catalogue
      // passed clean. Measured on the real oracle before the fix, with a new
      // check written in exactly this shape.
      //
      // Both are now SITES, which is better than "unattributed": the check
      // reaches the inventory with its message and the catalogue demands a
      // row for it like any other.
      const String hidden = '''
Future<void> expectUiSane(WidgetTester tester) async {
  final List<String> violations = <String>[];
  violations.addAll(_hiddenCheck(tester));
}

List<String> _hiddenCheck(WidgetTester tester) {
  final List<String> out = <String>[];
  final String message = 'this control is broken in a brand new way';
  out.add(message);
  final String interpolated = '\${a}: \${b}';
  out.add(interpolated);
  return out;
}
''';
      final OracleCheckInventory inventory = parseOracleCheckInventory(hidden);
      expect(
        inventory.sites.map((OracleCheckSite s) => s.message),
        unorderedEquals(<String>[
          'this control is broken in a brand new way',
          '*: *',
        ]),
      );
      expect(
        inventory.unattributedLiterals,
        isEmpty,
        reason: 'both are accounted for as sites now, so neither should also '
            'be reported as unclaimed',
      );
    });

    test('a RAW string is not mistaken for a message', () {
      // `_describeOverflow`'s `RegExp(r'A (\\w+) overflowed by ...')` is a
      // pattern, not a violation, and reporting it would make the reverse
      // scan noise a reader learns to append to.
      const String withRegex = '''
Future<void> expectUiSane(WidgetTester tester) async {
  final List<String> violations = <String>[];
  violations.addAll(_rawCheck(tester));
}

List<String> _rawCheck(WidgetTester tester) {
  final RegExp overflow = RegExp(r'A thing overflowed by some pixels here');
  final List<String> out = <String>[];
  return out;
}
''';
      expect(
        parseOracleCheckInventory(withRegex).unattributedLiterals,
        isEmpty,
      );
    });

    test('refuses a source with no expectUiSane rather than returning none',
        () {
      expect(
        () => parseOracleCheckInventory('void main() {}'),
        throwsA(isA<StateError>()),
      );
    });

    test('the real oracle yields a non-trivial inventory', () {
      // A floor is the WEAKEST thing this file does — it was 10 against a
      // measured 12, two sites of slack, and a floor can never notice a check
      // the parser failed to recognise at all. The real guard is the
      // bidirectional pair above: orphan sites AND unattributed literals.
      // This stays as the coarse "the derivation did not collapse" tripwire,
      // moved up to what is actually there.
      expect(inventory.sites.length, greaterThanOrEqualTo(12));
      expect(inventory.reachedFunctions, contains('_tapRouteViolations'));
      expect(inventory.reachedFunctions, contains('_measureText'));
    });
  });

  test('the coverage table is current', () {
    final String rendered = _renderTable(inventory);
    final File file = File(_tablePath);
    if (Platform.environment['UI_ORACLE_COVERAGE'] == 'write') {
      file.writeAsStringSync(rendered);
    }
    expect(
      file.existsSync(),
      isTrue,
      reason: '$_tablePath is missing. Regenerate with '
          'UI_ORACLE_COVERAGE=write flutter test '
          'test/ui_oracle/adversarial_catalogue_test.dart',
    );
    expect(
      file.readAsStringSync(),
      rendered,
      reason: 'the committed coverage table no longer matches the catalogue. '
          'Regenerate with UI_ORACLE_COVERAGE=write flutter test '
          'test/ui_oracle/adversarial_catalogue_test.dart and READ THE DIFF — '
          'a row moving from caught to not caught is a regression, not a '
          'refresh.',
    );
  });
}

// -----------------------------------------------------------------------------
// The table
// -----------------------------------------------------------------------------

String _preFixColumn(CatalogueRow row) {
  if (row.externalFixture != null) {
    return 'not measured here — the fix lane owns the fixture';
  }
  if (row.legacyOwnerInPath == null && row.legacyRoutesGt1 == null) {
    return 'no earlier variant of this check is kept executable';
  }
  final List<String> parts = <String>[];
  if (row.legacyRoutesGt1 != null) {
    parts.add(row.legacyRoutesGt1!
        ? '`routes > 1` only: reports'
        : '`routes > 1` only: SILENT');
  }
  if (row.legacyOwnerInPath != null) {
    parts.add(row.legacyOwnerInPath!
        ? 'owner-anywhere-in-path: SILENT'
        : 'owner-anywhere-in-path: reports');
  }
  return parts.join('; ');
}

String _statusColumn(CatalogueRow row) => switch (row.status) {
      RowStatus.caught => 'caught',
      RowStatus.caughtElsewhere => 'caught (fix lane)',
      RowStatus.notCaught => '**NOT CAUGHT**',
      RowStatus.noFixture => '**NO FIXTURE**',
    };

/// How many `notCaught` rows belong to [gap].
///
/// DERIVED, because the sentences in the standfirst used to say "three"
/// twice in hardcoded prose sitting directly under the derived `**$missed**`
/// bullet. Add or close one row and the generated table contradicted its own
/// count — with the freshness test green, because the prose matched the file
/// it had just written.
int _missedWithGap(String gap) => catalogue
    .where((CatalogueRow row) =>
        row.status == RowStatus.notCaught && row.gap == gap)
    .length;

String _renderTable(OracleCheckInventory inventory) {
  final int unreachableByRoute = _missedWithGap('a11y-route-is-not-a-finger');
  final int unreachableByRemoval =
      _missedWithGap('removed-control-out-of-contract');
  final int caught = catalogue
      .where((CatalogueRow r) =>
          r.status == RowStatus.caught &&
          r.defectClass != DefectClass.differential)
      .length;
  final int controls = catalogue
      .where((CatalogueRow r) => r.defectClass == DefectClass.differential)
      .length;
  final int elsewhere = catalogue
      .where((CatalogueRow r) => r.status == RowStatus.caughtElsewhere)
      .length;
  final int missed = catalogue
      .where((CatalogueRow r) => r.status == RowStatus.notCaught)
      .length;
  final int none =
      catalogue.where((CatalogueRow r) => r.status == RowStatus.noFixture).length;

  final StringBuffer out = StringBuffer()
    ..writeln('# What `expectUiSane` catches')
    ..writeln()
    ..writeln('GENERATED by `test/ui_oracle/adversarial_catalogue_test.dart`.')
    ..writeln('Do not edit by hand — regenerate with')
    ..writeln('`UI_ORACLE_COVERAGE=write flutter test '
        'test/ui_oracle/adversarial_catalogue_test.dart`.')
    ..writeln()
    ..writeln('The check list is read off `lib/testing/expect_ui_sane.dart` '
        'at run time, so a check')
    ..writeln('added, deleted or reworded there changes this table on the '
        'next run.')
    ..writeln()
    ..writeln('## Read this before trusting a green run')
    ..writeln()
    ..writeln('- **${inventory.sites.length}** violations `expectUiSane` can '
        'emit, derived from its source.')
    ..writeln('- **$caught** shapes caught, with a fixture in this lane.')
    ..writeln('- **$elsewhere** shapes caught, fixtured in the '
        'review-findings lane.')
    ..writeln('- **$missed** shapes NOT CAUGHT — each one silent in the '
        'oracle and proved broken')
    ..writeln('  independently: on the frame for the unreadable ones, by a '
        'REAL TAP that does not')
    ..writeln('  fire the callback for the $unreachableByRoute whose route no '
        'finger can take.')
    ..writeln('- **$none** check with no fixture anywhere.')
    ..writeln('- **$controls** differential rows: shapes that must produce NO '
        'violation.')
    ..writeln()
    ..writeln('**The shape of the result.** An UNREACHABLE shape is caught '
        'when some MECHANISM takes')
    ..writeln('the pointer away from the whole control — IgnorePointer, '
        'AbsorbPointer, a zero-size or')
    ..writeln('offset child, a sibling painted over it. $unreachableByRoute '
        'unreachable shapes are NOT')
    ..writeln('caught, and they are the ones where the control takes a '
        'pointer somewhere and still')
    ..writeln('cannot be activated: `Semantics(onTap:)` declares an '
        'ACCESSIBILITY route and creates no')
    ..writeln('pointer handler, so nothing in the render tree says which '
        'render object — if any —')
    ..writeln('implements it. Those rows are proved by a REAL TAP that does '
        'not fire the callback. Note')
    ..writeln('what one of them is: the differential control this lane is '
        'built on is itself')
    ..writeln('pointer-inert.')
    ..writeln()
    ..writeln('Every UNREADABLE shape probed is missed: the contrast rule '
        'reads its ink from the')
    ..writeln('resolved TextStyle, so no defect that changes the ink at PAINT '
        'time can reach it.')
    ..writeln('$unreachableByRemoval further unreachable rows are missed for '
        'a third reason — the control')
    ..writeln('is gone from layout, paint and semantics alike, and a '
        'surface-level oracle with no list')
    ..writeln('of what SHOULD be there has nothing to measure.')
    ..writeln()
    ..writeln('A green run of the oracle means the surface passes the checks '
        'in the first table.')
    ..writeln('It says NOTHING about the shapes in the second.')
    ..writeln()
    ..writeln('`unreachable` covers every way a control cannot be taken: off '
        'the view, under the')
    ..writeln('target-size floor, covered by another control, or dead to the '
        'hit test.')
    ..writeln()
    ..writeln('## Caught')
    ..writeln()
    ..writeln('| shape | class | check | fixture | pre-fix rules |')
    ..writeln('| --- | --- | --- | --- | --- |');
  for (final CatalogueRow row in catalogue) {
    if (row.status != RowStatus.caught &&
        row.status != RowStatus.caughtElsewhere) {
      continue;
    }
    final String fixture = row.externalFixture != null
        ? '`broken_surfaces.dart#${row.externalFixture}`'
        : '`adversarial_surfaces.dart`';
    out.writeln('| `${row.shape}` | ${row.defectClass.name} | '
        '${row.checkId == null ? '_(control)_' : '`${row.checkId}`'} | '
        '$fixture | ${_preFixColumn(row)} |');
  }

  out
    ..writeln()
    ..writeln('## Not caught')
    ..writeln()
    ..writeln('| shape | class | status | gap |')
    ..writeln('| --- | --- | --- | --- |');
  for (final CatalogueRow row in catalogue) {
    if (row.status != RowStatus.notCaught &&
        row.status != RowStatus.noFixture) {
      continue;
    }
    out.writeln('| `${row.shape}` | ${row.defectClass.name} | '
        '${_statusColumn(row)} | `${row.gap}` |');
  }

  out
    ..writeln()
    ..writeln('## Gaps')
    ..writeln();
  for (final MapEntry<String, String> gap in gaps.entries) {
    out
      ..writeln('### `${gap.key}`')
      ..writeln()
      ..writeln(gap.value)
      ..writeln();
  }

  out
    ..writeln('## Shapes the review-findings lane owns')
    ..writeln()
    ..writeln('Slugs minted here: the nine oracle review findings have no '
        'canonical numbering in')
    ..writeln('this repo, so a row pointing at "finding 3" would point at a '
        'list that does not exist.')
    ..writeln();
  for (final MapEntry<String, String> owned in ownedByFixLane.entries) {
    out.writeln('- **`${owned.key}`** — ${owned.value}');
  }

  out
    ..writeln()
    ..writeln('## Every shape, in full')
    ..writeln();
  for (final CatalogueRow row in catalogue) {
    out
      ..writeln('### `${row.shape}` — ${_statusColumn(row)}')
      ..writeln()
      ..writeln(row.summary)
      ..writeln();
  }

  return out.toString();
}
