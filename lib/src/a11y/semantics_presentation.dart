// Whether the accessibility tree PRESENTS a semantics node to the user.
//
// PRODUCTION-SAFE ON PURPOSE. This library imports `package:flutter/semantics.dart`
// and nothing else — in particular not `package:flutter_test` — because it has
// TWO callers on opposite sides of the release graph and they must not be
// allowed to drift apart again:
//
//   * `lib/testing/semantics_geometry.dart` — the UI Oracle's walk, which is
//     test-only and does import flutter_test; and
//   * `lib/src/probe/probe_api.dart` — the runtime probe, which SHIPS.
//
// WHY ONE PREDICATE AND NOT TWO. The oracle gained this exclusion (TRD 23-xx,
// the `scrolledListRows` fixture) and the probe did not, and the two answers
// immediately disagreed about the same tree: the oracle skipped a `ListView`'s
// off-screen rows while `EdenProbeApi.tree()` handed a driver those same rows
// as clickable targets, and handed it a control merged into its parent TWICE
// under one identifier with two different rects. A driver that clicks what the
// probe reports and an oracle that asserts over what the oracle reports were
// looking at two different screens.
//
// A shared predicate is what makes "the probe and the oracle agree" a fact
// about ONE function rather than a convention two files are each expected to
// remember. `test/probe/probe_oracle_presentation_agreement_test.dart` holds
// them to it over the same pumped trees.
library;

import 'package:flutter/semantics.dart';

/// Whether the accessibility tree publishes [node] as something a user can
/// actually see and reach.
///
/// WHY THIS EXISTS. A `ListView` builds a few rows beyond its viewport (the
/// cache extent) and publishes them as real semantics nodes carrying their
/// identifiers, their labels and their tap routes — flagged `isHidden`,
/// because no user can see them. Every geometry rule in this package used to
/// walk those rows like any other, and a CORRECT 30-row list came back with
/// one "inert to a real tap" violation per off-screen row. Measured on
/// `test/testing/_fixtures/broken_surfaces.dart`'s `scrolledListRows`: five
/// false accusations on a screen with nothing wrong with it.
///
/// That is the pressure that gets an oracle switched off, or gets identifier
/// sets dumped into an escape hatch — so the exclusion is encoded rather than
/// left to the consumer.
///
/// The three predicates are exactly the ones `flutter_test`'s own
/// `MinimumTapTargetGuideline` and `LabeledTapTargetGuideline` apply, named
/// here rather than reached for because they are private to those classes:
///
///  * [SemanticsNode.isMergedIntoParent] — the node does not stand on its own;
///    its parent is the control. Reporting it separately is how one control
///    came back from the probe twice, under one identifier, with two rects.
///  * [SemanticsNode.isInvisible] — an empty rect: there is no geometry to
///    measure.
///  * `isHidden` — published, but not presented.
bool isPresentedToUser(SemanticsNode node) =>
    !node.isMergedIntoParent &&
    !node.isInvisible &&
    !node.flagsCollection.isHidden;
