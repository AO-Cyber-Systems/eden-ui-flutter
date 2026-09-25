// Hand-built geometry fixtures for the UI Oracle semantics helpers.
//
// Every fixture in this file is written by hand, one widget tree per getter,
// readable top to bottom. Do NOT generate these from a list of names and do NOT
// add a loop that fabricates variants — the point of a fixture is that a human
// can read the exact tree an assertion is made against.
//
// NOTE ON IMPORTS: this file lives in `test_support/`, which is a top-level
// directory and NOT part of the package's `lib/`. There is therefore no
// `package:eden_ui_flutter/...` URI for it. Tests reach it with a relative
// import: `../../test_support/ui_oracle/_fixtures/geometry_fixtures.dart`.
library;

import 'package:flutter/material.dart';

/// Identifier carried by the single narrow control in [narrowChildInWideRow].
const String kFxNarrowChild = 'fx-narrow-child';

/// Identifiers carried by the two controls in [twoSiblingControls].
const String kFxSiblingA = 'fx-sibling-a';
const String kFxSiblingB = 'fx-sibling-b';

/// Identifiers used by [nestedSemanticsWithoutContainer].
const String kFxParent = 'fx-parent';
const String kFxNestedNoContainer = 'fx-nested-no-container';

/// A 360-wide row holding exactly one 40x40 identified control.
///
/// This is the 40-vs-360 case: a naive "read the rect off the nearest
/// container" implementation answers 360 (the row), the correct answer is 40
/// (the control). See `test/ui_oracle/semantics_geometry_test.dart` case 5.
Widget get narrowChildInWideRow => SizedBox(
  width: 360,
  height: 60,
  child: Row(
    children: <Widget>[
      Semantics(
        container: true,
        identifier: kFxNarrowChild,
        button: true,
        child: const SizedBox(width: 40, height: 40),
      ),
    ],
  ),
);

/// Two 40x40 identified controls separated by a 24px gap inside a 360-wide row.
///
/// Used to prove sibling rects are disjoint without the caller doing matrix
/// maths. See `test/ui_oracle/semantics_geometry_test.dart` case 6.
Widget get twoSiblingControls => SizedBox(
  width: 360,
  height: 60,
  child: Row(
    children: <Widget>[
      Semantics(
        container: true,
        identifier: kFxSiblingA,
        button: true,
        child: const SizedBox(width: 40, height: 40),
      ),
      const SizedBox(width: 24),
      Semantics(
        container: true,
        identifier: kFxSiblingB,
        button: true,
        child: const SizedBox(width: 40, height: 40),
      ),
    ],
  ),
);

/// A 200x200 identified container whose 40x40 identified child DELIBERATELY
/// omits `container: true`.
///
/// This fixture encodes an SDK-VERSION-DEPENDENT Flutter behaviour and MUST
/// NOT be "fixed" by adding `container: true` to the inner [Semantics]:
/// the omission IS the measurement.
///
/// What it measures, on the two SDKs this repo has run it on:
///
/// * Flutter 3.41.9 — the inner annotation formed no boundary. It merged
///   UPWARD into the parent: one node only, the parent's, carrying the
///   parent's 200x200 rect and the child's `button: true` flag, and the inner
///   identifier was not published at all.
/// * Flutter 3.47.4 (the version CI pins) — the inner annotation publishes
///   its OWN node, a child of the parent's, with the control's own 40x40 rect
///   and the button flag on it. The parent keeps its identifier and rect.
///
/// The stable release that changed this was not narrowed; both ends were
/// measured with this fixture (CI run 35898905034).
///
/// On web the semantics node — not the widget — is the click target
/// (memory note `flutter-web-semantics-node-is-the-click-target`), which is
/// why the rect a nested control publishes is worth pinning either way:
/// `test/ui_oracle/semantics_geometry_test.dart` case 7 asserts the 3.47.4
/// topology and fails loudly if a future SDK moves it again.
Widget get nestedSemanticsWithoutContainer => Center(
  // The Center matters: wrap() lays its child out at a TIGHT width, which
  // would stretch the 200x200 parent. Centering hands the parent loose
  // constraints so it keeps the size this fixture declares.
  child: Semantics(
    container: true,
    identifier: kFxParent,
    child: SizedBox(
      width: 200,
      height: 200,
      child: Center(
        child: Semantics(
          identifier: kFxNestedNoContainer,
          button: true,
          child: const SizedBox(width: 40, height: 40),
        ),
      ),
    ),
  ),
);
