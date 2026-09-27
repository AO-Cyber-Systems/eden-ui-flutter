// The input modality a surface is driven with.
//
// PRODUCTION-SAFE ON PURPOSE. This library imports NOTHING — in particular not
// `package:flutter_test` — so `EdenStory` (lib/dev_app/) and any consumer
// widget can declare a modality without dragging the test framework into a
// release graph. `lib/testing/expect_ui_sane.dart` re-exports it, so a test
// that imports only `package:eden_ui_flutter/testing.dart` still sees it.
library;

/// What a surface is DRIVEN WITH. Selects the tap-target floor, and nothing
/// else.
///
/// WHY THIS EXISTS. The 48dp Material floor
/// (`androidTapTargetGuideline`) and the 44pt iOS HIG floor
/// (`iOSTapTargetGuideline`) are TOUCH guidance — they size a control for a
/// fingertip. For pointer-driven UI the applicable standard is WCAG 2.5.8
/// Target Size (Minimum), which is 24x24 CSS px at AA; 2.5.5 Target Size
/// (Enhanced), 44x44, is AAA. Asserting a touch floor on a pointer surface is
/// therefore not a STRICTER standard, it is the WRONG standard — and the only
/// pressure it can create is to weaken the oracle, which is how oracles rot.
///
/// This is NOT a suppression or exception mechanism. There is deliberately no
/// way to waive the tap-target rule for a surface; there is only a way to
/// declare, honestly, what input that surface takes. It is the same
/// state-conditional shape the Surface Spec uses for `behaviors[]`/`when`: the
/// rule that applies is a function of declared state, and every path still
/// asserts a real floor (compare case 7 and case 8 in
/// `test/testing/expect_ui_sane_test.dart` — the pointer floor rejects 20x20
/// and accepts 40px, so it is neither vacuous nor the touch rule in disguise).
///
/// A surface that ships to BOTH is [touch]: the stricter floor is the honest
/// answer when a fingertip can reach the control at all. [touch] is also the
/// default of [expectUiSane], so an author who says nothing gets the stricter
/// rule rather than the looser one.
enum EdenInputModality {
  /// Mouse, trackpad, stylus or keyboard-driven. Asserts WCAG 2.5.8 Target
  /// Size (Minimum): 24x24.
  ///
  /// The worked example is the Eden desktop rail: 40px nav rows on a 42px
  /// pitch (`eden_desktop_layout.dart`). 40px clears 24x24 comfortably, and
  /// it is not reachable by a fingertip on the surfaces that use it.
  pointer,

  /// Finger-driven, or reachable by a finger on any surface this ships to.
  /// Asserts BOTH `androidTapTargetGuideline` (48dp) and
  /// `iOSTapTargetGuideline` (44pt).
  ///
  /// Both floors are checked, deliberately — a 46px target is a real defect on
  /// Android, and tuning a fixture to sit between the two would hide it.
  touch,
}
