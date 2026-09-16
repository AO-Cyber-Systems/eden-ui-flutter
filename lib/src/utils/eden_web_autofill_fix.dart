// lib/src/utils/eden_web_autofill_fix.dart
//
// Facade for the web-only autofill GEOMETRY shim, plus the pure restyle
// predicate that decides which elements the shim is allowed to touch.
//
// WHY THIS EXISTS
//   Flutter's web engine collapses every NON-FOCUSED autofill input to a zero
//   sized box.  In
//   `engine/src/flutter/lib/web_ui/lib/src/engine/text_editing/text_editing.dart`,
//   `_styleAutofillElements()` does:
//
//     if (shouldHideElement) {
//       elementStyle
//         ..width = '0'
//         ..height = '0';
//     }
//
//   and `EngineAutofillForm.fromFrameworkMessage` calls it with
//   `shouldHideElement: !isSafariDesktopStrategy`.  Flutter hit this exact
//   problem before and fixed it ONLY for Safari Desktop (flutter#71275).  On
//   Chrome, Edge, Brave and Firefox every field except the focused one is a
//   0x0 box.
//
//   Password managers deliberately skip non-visible fields when classifying a
//   login form, and 1Password's own guidance is to use `opacity: 0` rather
//   than `width: 0; height: 0`.  So the password field is never seen, the form
//   is never classified as a login form, and no fill is ever offered.  Hints,
//   `name`, `id`, `type=password` and the `<form>` are all already correct --
//   measured live and recorded in `40-19-BROWSER-EVIDENCE.md`.  Geometry is
//   the only remaining blocker.
//
//   Upstream: flutter#61301 (open since 2020, P1) and flutter#174773.  If the
//   engine ever stops collapsing these elements, this shim becomes redundant
//   and should be deleted.
//
// FLOOR
//   Designed to the declared `>=3.27.0` Flutter floor.  Nothing here uses an
//   API newer than that floor.
//
// WHAT IS AND IS NOT TEST-COVERED
//   The predicate below is pure Dart, compiles on every platform, and IS
//   covered by `test/widgets/eden_web_autofill_fix_test.dart`.  The DOM half
//   -- the MutationObserver and the actual restyle -- is web-only and CANNOT
//   be exercised by `flutter test`, because `kIsWeb` is a compile-time
//   constant and false on the VM.  That half is verified by the recorded
//   real-browser evidence, not by the unit suite.  Do not add a test that
//   appears to cover it.

// The conditional export picks the real implementation on web and a total
// no-op everywhere else, so non-web builds never see `dart:js_interop`.
//
// NOTE ON THE IMPORT CYCLE: the web implementation imports this library back
// for the predicate and the constants below. Dart resolves that cycle without
// complaint, and it keeps the one piece of real decision logic in a file that
// every platform compiles and every test can reach.
export 'eden_web_autofill_fix_stub.dart'
    if (dart.library.js_interop) 'eden_web_autofill_fix_web.dart';

/// Inline width the shim gives a collapsed autofill input, in CSS pixels.
///
/// Any non-zero box will do; a password manager's heuristic asks whether the
/// field has a real box, not how big it is. `opacity: 0` is what keeps it
/// invisible to the user.
const String kEdenWebAutofillFixWidth = '160px';

/// Inline height the shim gives a collapsed autofill input, in CSS pixels.
const String kEdenWebAutofillFixHeight = '24px';

/// Decides whether the shim may restyle an element, from values that can be
/// read off any DOM element without needing a DOM to test it.
///
/// Returns true only when ALL of the following hold:
///
/// * the element is an `<input>` or a `<textarea>` -- nothing else is ever an
///   autofill target;
/// * its `type` is not `submit` -- the engine's hidden `submitBtn` is the SAVE
///   trigger that `finishAutofillContext` clicks (`text_editing.dart:2245`),
///   not a fill target. It must stay 0x0 and offscreen;
/// * its INLINE width or height is zero -- which is precisely the signature of
///   an element the engine has collapsed. The FOCUSED field carries real
///   dimensions and so is never matched, which is what keeps the shim from
///   fighting the engine over the field the user is actually typing in.
///
/// [tagName] is compared case-insensitively, matching `Element.tagName`, which
/// reports upper case for HTML elements. [inlineWidth] and [inlineHeight] are
/// the values of `element.style.width` / `element.style.height`, i.e. the
/// INLINE style only -- never the computed style.
bool edenWebAutofillFixShouldRestyle({
  required String tagName,
  required String type,
  required String inlineWidth,
  required String inlineHeight,
}) {
  final String tag = tagName.trim().toLowerCase();
  if (tag != 'input' && tag != 'textarea') {
    return false;
  }
  if (type.trim().toLowerCase() == 'submit') {
    return false;
  }
  return _isZeroLength(inlineWidth) || _isZeroLength(inlineHeight);
}

/// True when a CSS length string means zero.
///
/// The engine assigns the bare string `'0'`; the CSSOM normalises that to
/// `'0px'` on read in every browser tested. Both spellings are accepted so the
/// predicate does not depend on that normalisation, and an empty value (no
/// inline dimension at all) is deliberately NOT zero -- an element the engine
/// has not collapsed must be left alone.
bool _isZeroLength(String value) {
  final String v = value.trim().toLowerCase();
  return v == '0' || v == '0px';
}
