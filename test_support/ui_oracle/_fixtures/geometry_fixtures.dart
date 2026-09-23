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
Widget get narrowChildInWideRow => const SizedBox(
  width: 360,
  height: 60,
  child: Row(
    children: <Widget>[
      Semantics(
        container: true,
        identifier: kFxNarrowChild,
        button: true,
        child: SizedBox(width: 40, height: 40),
      ),
    ],
  ),
);

/// Two 40x40 identified controls separated by a 24px gap inside a 360-wide row.
///
/// Used to prove sibling rects are disjoint without the caller doing matrix
/// maths. See `test/ui_oracle/semantics_geometry_test.dart` case 6.
Widget get twoSiblingControls => const SizedBox(
  width: 360,
  height: 60,
  child: Row(
    children: <Widget>[
      Semantics(
        container: true,
        identifier: kFxSiblingA,
        button: true,
        child: SizedBox(width: 40, height: 40),
      ),
      SizedBox(width: 24),
      Semantics(
        container: true,
        identifier: kFxSiblingB,
        button: true,
        child: SizedBox(width: 40, height: 40),
      ),
    ],
  ),
);

/// A 200x200 identified container whose 40x40 identified child DELIBERATELY
/// omits `container: true`.
///
/// This fixture encodes a known Flutter behaviour and MUST NOT be "fixed" by
/// adding `container: true` to the inner [Semantics]. A nested `Semantics`
/// without `container: true` does not form its own semantics boundary; its
/// annotations are merged into the enclosing node, so the accessibility tree
/// publishes the PARENT's 200x200 rect for it, not its own 40x40.
///
/// On web the semantics node — not the widget — is the click target
/// (memory note `flutter-web-semantics-node-is-the-click-target`), so a
/// geometry assertion built on this node is asserting the wrong box. 23-02's
/// `expectUiSane` turns this into a hard failure; this fixture is the tripwire
/// that keeps the behaviour observable in the meantime.
Widget get nestedSemanticsWithoutContainer => const Semantics(
  container: true,
  identifier: kFxParent,
  child: SizedBox(
    width: 200,
    height: 200,
    child: Center(
      child: Semantics(
        identifier: kFxNestedNoContainer,
        button: true,
        child: SizedBox(width: 40, height: 40),
      ),
    ),
  ),
);
