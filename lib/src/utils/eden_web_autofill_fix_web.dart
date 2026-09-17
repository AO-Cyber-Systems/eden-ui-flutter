// lib/src/utils/eden_web_autofill_fix_web.dart
//
// Web implementation of the autofill geometry shim. See
// `eden_web_autofill_fix.dart` for the full root cause; the short version is
// that Flutter's engine sets `width: 0; height: 0` on every autofill input
// that is not currently focused, and password managers skip invisible fields,
// so the password field is never seen and no fill is ever offered.
//
// The shim gives those collapsed inputs a real box with `opacity: 0`: visible
// to a manager's heuristic, invisible and non-interactive to the user.
//
// WHY A MutationObserver AND NOT A ONE-SHOT SWEEP
//   The engine REWRITES these inline styles on every focus change -- the field
//   the user just left is re-collapsed as the newly focused one is expanded.
//   A sweep at install time would be undone by the first focus swap, so the
//   attribute observer is load-bearing, not belt-and-braces.
//
// WHY opacity AND NOT visibility/display
//   `visibility: hidden` and `display: none` both remove the element from the
//   visibility heuristic again, which is the exact problem being fixed. Only
//   `opacity: 0` keeps a real, laid-out box.
//
// WHY `important`
//   The engine writes its `width`/`height` as INLINE style. An inline
//   declaration without `important` cannot beat another inline declaration
//   applied later, so the shim marks its own properties `important`. The
//   engine can still clear that by assigning the property again -- which is
//   precisely the mutation the observer is watching for.

import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import 'eden_web_autofill_fix.dart';

/// `Node.ELEMENT_NODE`. Used instead of an interop type test so the check does
/// not depend on any API newer than the declared floor.
const int _kElementNode = 1;

/// Opt-out switch. Set this to false BEFORE the first `EdenAutofillScope`
/// mounts to prevent the shim installing at all.
///
/// Setting it after installation does not uninstall anything; the observer is
/// process-lifetime by design, exactly like the one-shot browser-context-menu
/// disable in `EdenSelectableRegion`.
bool edenWebAutofillFixEnabled = true;

/// Library-private latch so repeated `EdenAutofillScope` mounts install the
/// observer exactly once per process.
bool _installed = false;

/// Retained so [edenResetWebAutofillFixForTest] can disconnect it rather than
/// leaking observers across resets.
web.MutationObserver? _observer;

/// Whether the observer is currently installed.
bool get edenWebAutofillFixInstalled => _installed;

/// Installs the geometry shim. Idempotent: at most one observer per process.
///
/// Callers must already have checked [kIsWeb]; this library is only reachable
/// on web via the conditional export in `eden_web_autofill_fix.dart`.
void edenInstallWebAutofillFix() {
  if (_installed || !edenWebAutofillFixEnabled) {
    return;
  }

  final web.Element? root = _observationRoot();
  if (root == null) {
    // No document to observe yet. Deliberately do NOT latch, so a later scope
    // mount retries instead of permanently recording a failed attempt --
    // the same recovery shape as `_disableBrowserContextMenuOnce`.
    return;
  }

  _installed = true;

  // Elements already present when the first scope mounts.
  _sweep(root);

  final web.MutationObserver observer =
      web.MutationObserver(_onMutations.toJS);
  observer.observe(
    root,
    web.MutationObserverInit(
      childList: true,
      subtree: true,
      attributes: true,
      // Only `style` matters: the engine's collapse is an inline-style write.
      attributeFilter: <JSString>['style'.toJS].toJS,
    ),
  );
  _observer = observer;
}

/// Disconnects the observer and restores defaults so tests are not
/// order-dependent.
@visibleForTesting
void edenResetWebAutofillFixForTest() {
  _observer?.disconnect();
  _observer = null;
  _installed = false;
  edenWebAutofillFixEnabled = true;
}

/// The narrowest element that contains the engine's autofill inputs.
///
/// Flutter parks its text-editing DOM inside `flt-text-editing-host`, so
/// scoping there keeps the observer off the rest of the document. That host
/// does not exist until the engine first needs it, which can be after the
/// first scope mounts, so `document.body` is the fallback -- a strict superset
/// that always contains the inputs wherever the engine puts them.
web.Element? _observationRoot() {
  final web.Element? host =
      web.document.querySelector('flt-text-editing-host');
  if (host != null) {
    return host;
  }
  return web.document.body ?? web.document.documentElement;
}

/// Handles a batch of mutations from the observer.
///
/// Signature matches the DOM `MutationCallback`: `(records, observer)`.
void _onMutations(
  JSArray<web.MutationRecord> records,
  web.MutationObserver observer,
) {
  for (final web.MutationRecord record in records.toDart) {
    final String type = record.type;
    if (type == 'attributes') {
      // The engine re-collapsed something -- most often the field that just
      // lost focus.
      _restyleIfCollapsed(record.target);
    } else if (type == 'childList') {
      final web.NodeList added = record.addedNodes;
      for (int i = 0; i < added.length; i++) {
        final web.Node? node = added.item(i);
        if (node == null) {
          continue;
        }
        _restyleIfCollapsed(node);
        _sweepNode(node);
      }
    }
  }
}

/// Restyles every already-collapsed input under [root].
void _sweep(web.Element root) {
  final web.NodeList matches = root.querySelectorAll('input, textarea');
  for (int i = 0; i < matches.length; i++) {
    final web.Node? node = matches.item(i);
    if (node != null) {
      _restyleIfCollapsed(node);
    }
  }
}

/// Restyles collapsed inputs among [node]'s descendants, when [node] is an
/// element. Added subtrees arrive whole, so the added node itself is rarely
/// the input.
void _sweepNode(web.Node node) {
  if (node.nodeType != _kElementNode) {
    return;
  }
  _sweep(node as web.Element);
}

/// Applies the fix to [node] when, and only when, the shared predicate in
/// `eden_web_autofill_fix.dart` says it is a collapsed, non-submit autofill
/// input.
///
/// Everything this reads is inline style, so the FOCUSED field -- which
/// carries real dimensions -- is never matched and never fought over.
void _restyleIfCollapsed(web.Node node) {
  if (node.nodeType != _kElementNode) {
    return;
  }
  final web.Element element = node as web.Element;
  final web.CSSStyleDeclaration style = (element as web.HTMLElement).style;

  final bool shouldRestyle = edenWebAutofillFixShouldRestyle(
    tagName: element.tagName,
    // A `<textarea>`, and an `<input>` with no explicit type, both report null
    // here; neither is the submit button, so an empty string is the right
    // reading.
    type: element.getAttribute('type') ?? '',
    inlineWidth: style.width,
    inlineHeight: style.height,
  );
  if (!shouldRestyle) {
    return;
  }

  // `important` so a later inline write does not silently win. Re-entrancy is
  // bounded: this write fires the observer once more, and on that pass the
  // width is no longer zero, so the predicate returns false and it stops.
  style.setProperty('width', kEdenWebAutofillFixWidth, 'important');
  style.setProperty('height', kEdenWebAutofillFixHeight, 'important');
  style.setProperty('opacity', '0', 'important');
  style.setProperty('position', 'absolute', 'important');
  style.setProperty('pointer-events', 'none', 'important');
}
