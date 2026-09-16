// lib/src/widgets/eden_autofill_scope.dart
//
// EdenAutofillScope — the SAVE half of autofill.
//
// WHY THIS EXISTS
//   Autofill has two directions and this package only had one of them.  Correct
//   hints (`EdenFieldPurpose`, `EdenInput.purpose`) make a field FILLABLE.
//   Nothing in the package made a field SAVABLE, because that requires exactly
//   one call — `TextInput.finishAutofillContext(shouldSave: true)` — and it
//   appeared nowhere.  Without it no credential is ever offered for saving on
//   web, iOS or Android.
//
// FLOOR
//   Designed to the declared `>=3.27.0` floor, not to any newer local SDK.
//   `AutofillGroup`, `AutofillContextAction` and
//   `TextInput.finishAutofillContext` all exist from 3.16 onward.
//
// Convention: forward-don't-reimplement.  `StatefulWidget` only so callers have
// a State to reach for imperatively; nothing here fires on its own.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/eden_web_autofill_fix.dart';

/// Groups the credential fields in [child] into one autofill context and
/// exposes the one call that makes a platform offer to SAVE what was typed.
///
/// ## Fillable is not savable
///
/// Correct autofill hints — see `EdenFieldPurpose` and `EdenInput.purpose` —
/// make a field **fillable**: the OS, browser or password manager can push a
/// stored credential into it. They do nothing whatsoever for the other
/// direction. A field only becomes **savable** when something calls
/// [EdenAutofillScopeState.commit], which invokes
/// `TextInput.finishAutofillContext(shouldSave: true)`.
///
/// That call is the only trigger on any platform. On web the engine builds a
/// hidden `<form>` carrying a hidden `submitBtn`
/// (`text_editing.dart:243-346`) and `saveForms()` clicks it (`:2245`); that
/// synthetic click is what raises the browser's "Save password?" prompt. With
/// no call, credentials are never saved on web, iOS or Android.
///
/// ## Usage
///
/// Call [EdenAutofillScopeState.commit] only once the credential has actually
/// been ACCEPTED — after the login or signup request succeeds, never when the
/// button is pressed:
///
/// ```dart
/// Future<void> _signIn() async {
///   await api.login(email: _emailCtrl.text, password: _passwordCtrl.text);
///   if (!mounted) return;
///   EdenAutofillScope.of(context).commit();
/// }
/// ```
///
/// Committing after a REJECTED attempt makes the OS and 1Password offer to save
/// the wrong credentials, which the user then has to unpick by hand. That is
/// why [EdenForm] does not auto-commit: `EdenForm.commitAutofillOnSubmit`
/// defaults to `false`.
///
/// ## One group, one hint each
///
/// Do not place two fields that share a hint inside the same scope. The web
/// engine derives both `element.name` and `element.id` from the hint string
/// (`text_editing.dart:514-531`), so a new-password field and its confirmation
/// field both tagged `AutofillHints.newPassword` emit DUPLICATE DOM ids. See
/// `EdenFieldPurpose.newPasswordConfirm`, where that constraint and the
/// resulting hint choice are documented.
///
/// ## Web geometry: why mounting this scope also installs a DOM shim
///
/// On web this widget installs a one-shot geometry shim
/// (`edenInstallWebAutofillFix`, `lib/src/utils/eden_web_autofill_fix.dart`).
/// It exists because correct hints are still not enough on web.
///
/// Flutter's engine collapses every autofill input that is NOT currently
/// focused to a zero-sized box -- `_styleAutofillElements()` in the engine's
/// `text_editing.dart` sets `width: 0; height: 0`, called with
/// `shouldHideElement: !isSafariDesktopStrategy`, so the workaround Flutter
/// shipped for that problem applies to Safari Desktop only (flutter#71275).
/// Password managers deliberately skip non-visible fields when classifying a
/// login form, so the password field is never seen and no fill is offered.
///
/// The shim gives collapsed inputs a real box with `opacity: 0`. It never
/// touches the FOCUSED field (which has real dimensions) and never touches the
/// hidden `type=submit` button (which is the SAVE trigger and must stay 0x0).
/// Off web it is a compile-time no-op.
///
/// To opt out, set the flag once before the first scope mounts:
///
/// ```dart
/// void main() {
///   edenWebAutofillFixEnabled = false; // no-op off web
///   runApp(const MyApp());
/// }
/// ```
///
/// Upstream: flutter#61301 and flutter#174773. If the engine stops collapsing
/// these elements, the shim becomes redundant and should be removed.
///
/// ## Best effort, never a gate
///
/// Platform save prompts are imperfect upstream and this package does not
/// invent workarounds for them: flutter#116889 (iOS prompt sometimes absent),
/// flutter#69111 (Android), flutter#174773 and flutter#61301 (web password
/// managers and extensions). Treat autofill as best-effort and never gate app
/// functionality on a prompt appearing.
class EdenAutofillScope extends StatefulWidget {
  const EdenAutofillScope({
    super.key,
    required this.child,
    this.enabled = true,
    this.onDisposeAction = AutofillContextAction.cancel,
  });

  /// The subtree whose fields share one autofill context.
  final Widget child;

  /// What happens to the autofill context when the TOPMOST scope is disposed.
  ///
  /// Defaults to [AutofillContextAction.cancel], which is NOT Flutter's default.
  ///
  /// `AutofillGroup` defaults this to [AutofillContextAction.commit]
  /// (`widgets/autofill.dart:75`), and its `dispose` then calls
  /// `TextInput.finishAutofillContext()` with `shouldSave` defaulting to true
  /// (`widgets/autofill.dart:232-243`). That means simply NAVIGATING AWAY from a
  /// form offers to save whatever was typed — including after a failed sign-in,
  /// which is how a password manager ends up storing a wrong password.
  ///
  /// That implicit path would also bypass [EdenAutofillScope.commit] and
  /// `EdenForm.commitAutofillOnSubmit` entirely: both exist precisely so saving
  /// is a deliberate act taken only once the app knows the credential is good.
  /// A default of `commit` would make those controls decorative.
  ///
  /// So the default here is inverted: dispose CANCELS, and saving happens only
  /// through an explicit [commit] call. Pass
  /// [AutofillContextAction.commit] if a surface genuinely wants Flutter's
  /// implicit behaviour, and say why at the call site.
  final AutofillContextAction onDisposeAction;

  /// When false this widget is a pass-through — no [AutofillGroup] is
  /// installed, though the scope's State remains reachable so an enclosing
  /// widget can still resolve it.
  final bool enabled;

  /// The nearest enclosing scope, or null when there is none.
  ///
  /// Prefer this inside library widgets, which must not assert on callers who
  /// legitimately have no scope above them.
  static EdenAutofillScopeState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<EdenAutofillScopeState>();

  /// The nearest enclosing scope. Asserts, with a fix-it message, when absent.
  static EdenAutofillScopeState of(BuildContext context) {
    final state = maybeOf(context);
    assert(
      state != null,
      'No EdenAutofillScope found in context. Wrap the credential fields in an '
      'EdenAutofillScope, or place them inside an EdenForm or '
      'EdenAsyncFormScaffold, both of which provide one ambiently.',
    );
    return state!;
  }

  @override
  EdenAutofillScopeState createState() => EdenAutofillScopeState();
}

/// State for [EdenAutofillScope]. Nothing here runs automatically; both
/// [commit] and [cancel] are imperative, caller-driven actions.
class EdenAutofillScopeState extends State<EdenAutofillScope> {
  @override
  void initState() {
    super.initState();
    if (kIsWeb && widget.enabled) {
      // One-shot and idempotent, mirroring _disableBrowserContextMenuOnce() in
      // eden_selectable_region.dart: several scopes can mount in one app, and
      // only the first does any work. Off web this call compiles to a no-op.
      edenInstallWebAutofillFix();
    }
  }

  /// Ends the autofill context and asks the platform to SAVE what was entered.
  ///
  /// Call this ONLY after the credential has actually been accepted — after the
  /// login or signup request succeeds, not when the button is pressed. Calling
  /// it on a failed attempt makes the OS and 1Password offer to save WRONG
  /// credentials.
  ///
  /// This is the only trigger that produces a save prompt on any platform: on
  /// web `saveForms()` clicks the hidden form's `submitBtn`
  /// (`text_editing.dart:2245`).
  void commit() => TextInput.finishAutofillContext(shouldSave: true);

  /// Ends the autofill context WITHOUT offering to save. Use when the user
  /// abandons the flow.
  ///
  /// Never reach for this as a "safe default" in place of [commit] — tearing
  /// the context down without saving silently guarantees the credential is
  /// never stored. If you are not saving, do not call anything at all.
  void cancel() => TextInput.finishAutofillContext(shouldSave: false);

  @override
  Widget build(BuildContext context) =>
      widget.enabled
          ? AutofillGroup(
              // Explicit, and deliberately NOT Flutter's default of `commit` —
              // see [onDisposeAction]. Navigating away must never be a save.
              onDisposeAction: widget.onDisposeAction,
              child: widget.child,
            )
          : widget.child;
}
