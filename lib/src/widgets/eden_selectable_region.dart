// lib/src/widgets/eden_selectable_region.dart
//
// EdenSelectableRegion — one drop-in wrapper that makes an entire subtree's
// text drag-selectable and copyable, and that makes Flutter's own context menu
// actually appear on web.
//
// WHY THIS EXISTS
//   Flutter widgets are not selectable by default.  Before this widget,
//   `eden-ui-flutter` contained ZERO `SelectionArea`, ZERO `SelectableRegion`
//   and ZERO `contextMenuBuilder` (measured — `40-RESEARCH.md` §1): rendered
//   text simply could not be selected, anywhere.
//
//   On web there is a second, separate failure.  Flutter's context menu never
//   appears unless `BrowserContextMenu.disableContextMenu()` has been called —
//   `services/browser_context_menu.dart` documents that the browser's native
//   menu is enabled by default and Flutter's menus are hidden.  Wrapping a
//   subtree in a bare `SelectionArea` therefore still gives web users the
//   browser menu, not "Copy".  Both halves have to ship together, which is why
//   they are one widget rather than a bare `SelectionArea` at each call site.
//
// FLOOR
//   Designed to the declared `>=3.27.0` floor, not to any newer local SDK.
//   `SelectionArea`, `SelectionContainer.disabled`, `contextMenuBuilder` and
//   `BrowserContextMenu` all exist from 3.16 onward.  Flutter's newer
//   selection-listener widget does NOT exist at this floor and is deliberately
//   not used — `onSelectionChanged` (plain text, no offsets) is the entire
//   available notification surface.
//
// TIMING — THE MENU MUST BE OFF BEFORE ANY SelectableRegion BUILDS
//   `SelectableRegion.build` wraps its `SelectionContainer(registrar: this)` in
//   `PlatformSelectableRegionContextMenu` only while
//   `kIsWeb && BrowserContextMenu.enabled` (and not on Android/iOS). That
//   container is not keyed, so if the flag flips between two builds of one
//   region the container is re-inflated as a NEW State that registers itself
//   while the old one is still registered in the region's SINGLE `_selectable`
//   slot. The old State's dispose then nulls the slot, and the next time the
//   region's content empties the new State calls `remove()` on `_selectable!`:
//   "Null check operator used on a null value" in profile/release, and
//   `assert(_selectable == null)` in `add()` in debug.
//
//   `disableContextMenu()` only flips the flag after a platform-channel round
//   trip. This widget used to issue it fire-and-forget from `initState` and
//   build its `SelectionArea` in the same frame — i.e. with the flag still
//   true — so every region on screen at first load, the app's own included,
//   saw the flag change under it. Found in eden-biz's web console
//   (`.planning/debug/resolved/selectable-region-null-check-console.md`).
//
//   The fix has two halves:
//   * [edenPrepareSelectableRegionForWeb] — awaited before `runApp`, so the
//     flag is already false when anything builds. The only thing that can
//     protect a `SelectionArea` the APP owns.
//   * If the app did not call it, a region builds its child WITHOUT a
//     `SelectionArea` until the disable lands, then installs one — so its OWN
//     region is never built under the old flag value. The child is moved, not
//     re-created, across that switch (GlobalKey), so its State survives.
//
// Convention: forward-don't-reimplement, matching the other thin wrappers in
// this package.  `StatefulWidget` only because the one-shot web call belongs in
// `initState`, never in `build`, and the deferred install needs `setState`.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// Set once the browser context menu is KNOWN to be disabled — by this library,
/// or by the app before any region built. A failed attempt never sets it, so a
/// later call retries.
///
/// Process-global on purpose: [edenPrepareSelectableRegionForWeb] and every
/// [EdenSelectableRegion] share it. The Eden layouts and the library pages all
/// bake the widget in, so one app easily mounts several regions, and
/// `disableContextMenu()` is asynchronous and not free to re-issue.
bool _browserContextMenuDisabled = false;

/// The single in-flight disable, joined by every caller that arrives before it
/// settles. Cleared when it settles, success or failure.
Future<void>? _browserContextMenuDisableInFlight;

/// Debug-only: the "region built before the app prepared" warning has printed.
bool _debugWarnedUnpreparedRegion = false;

/// Test seam for the web branch, which is otherwise unreachable under the VM
/// `flutter test` runner (`kIsWeb` is a compile-time constant).
///
/// While non-null, and ONLY in debug builds (it is read inside an `assert`),
/// [edenPrepareSelectableRegionForWeb] and [EdenSelectableRegion] take their
/// web path on every platform and call this instead of
/// `BrowserContextMenu.disableContextMenu()`. Profile and release builds never
/// read it. Cleared by [edenResetSelectableRegionForTest].
@visibleForTesting
Future<void> Function()? debugEdenBrowserContextMenuDisableOverride;

/// Restores the process-global disable state so tests are not
/// order-dependent. Does NOT touch `BrowserContextMenu.enabled` itself — a web
/// test that disabled it for real must re-enable it.
@visibleForTesting
void edenResetSelectableRegionForTest() {
  _browserContextMenuDisabled = false;
  _browserContextMenuDisableInFlight = null;
  _debugWarnedUnpreparedRegion = false;
  debugEdenBrowserContextMenuDisableOverride = null;
}

/// Whether the web path applies: `kIsWeb`, or in debug builds also while
/// [debugEdenBrowserContextMenuDisableOverride] is set.
bool get _takeWebPath {
  bool web = kIsWeb;
  assert(() {
    if (debugEdenBrowserContextMenuDisableOverride != null) {
      web = true;
    }
    return true;
  }());
  return web;
}

Future<void> _invokeDisableContextMenu() {
  Future<void> Function() disable = BrowserContextMenu.disableContextMenu;
  assert(() {
    disable = debugEdenBrowserContextMenuDisableOverride ?? disable;
    return true;
  }());
  return disable();
}

/// Idempotent, shared disable of the browser context menu.
///
/// Returns null when the menu is already off — nothing to wait for — and
/// otherwise the single in-flight attempt, starting it if nobody has. The
/// returned future never completes with an error.
///
/// Callers MUST already have checked [_takeWebPath]: `disableContextMenu()`
/// asserts `kIsWeb` internally (`services/browser_context_menu.dart`).
Future<void>? _ensureBrowserContextMenuDisabled() {
  if (_browserContextMenuDisabled) {
    return null;
  }
  // Already off without us — e.g. the app awaited
  // `BrowserContextMenu.disableContextMenu()` itself before runApp. Latch it:
  // no second platform call, no deferral, no warning.
  if (!BrowserContextMenu.enabled) {
    _browserContextMenuDisabled = true;
    return null;
  }
  // `whenComplete` callbacks never run synchronously, so the `??=` assignment
  // always lands before the slot is cleared, even if the attempt fails at once.
  return _browserContextMenuDisableInFlight ??=
      _attemptBrowserContextMenuDisable().whenComplete(() {
    _browserContextMenuDisableInFlight = null;
  });
}

/// One attempt. A failure is reported, not thrown, and leaves the latch unset.
Future<void> _attemptBrowserContextMenuDisable() async {
  try {
    await _invokeDisableContextMenu();
    _browserContextMenuDisabled = true;
  } catch (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'eden_ui_flutter',
        context: ErrorDescription(
          'while disabling the browser context menu for EdenSelectableRegion',
        ),
      ),
    );
  }
}

/// Disables the browser's native context menu on web and waits until it has
/// taken effect, so that no `SelectableRegion` — [EdenSelectableRegion]'s or
/// one the app owns — is ever built while `BrowserContextMenu.enabled` is
/// still true. No-op off web.
///
/// Await it after `WidgetsFlutterBinding.ensureInitialized()` and BEFORE
/// `runApp`:
///
/// ```dart
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await edenPrepareSelectableRegionForWeb();
///   runApp(const MyApp());
/// }
/// ```
///
/// Why: `SelectableRegion` builds a different, unkeyed subtree depending on
/// that flag, and `disableContextMenu()` only flips it after a platform-channel
/// round trip. If the flip lands after a region's first build, the region's
/// next rebuild re-inflates its `SelectionContainer` and double-registers it —
/// "Null check operator used on a null value" in release. Without this call
/// [EdenSelectableRegion] still protects ITSELF (it defers its `SelectionArea`
/// until the disable lands, and warns once in debug), but it cannot protect a
/// `SelectionArea` the app installs itself, e.g. around its shell.
///
/// Idempotent and shared with every [EdenSelectableRegion]: once it has
/// succeeded no region re-issues the call, and concurrent calls join the one
/// in-flight attempt. If the menu is already disabled (the app awaited
/// `BrowserContextMenu.disableContextMenu()` itself), it returns at once.
///
/// Never completes with an error, so it cannot block boot. A failure is
/// reported through [FlutterError.reportError] (so `FlutterError.onError` and
/// crash reporting see it), is NOT latched, and the next call retries; the app
/// keeps working with the browser's own menu.
Future<void> edenPrepareSelectableRegionForWeb() async {
  if (!_takeWebPath) {
    return;
  }
  final Future<void>? pending = _ensureBrowserContextMenuDisabled();
  if (pending != null) {
    await pending;
  }
}

void _debugWarnUnpreparedRegion() {
  assert(() {
    if (!_debugWarnedUnpreparedRegion) {
      _debugWarnedUnpreparedRegion = true;
      debugPrint(
        'EdenSelectableRegion: built on web before the browser context menu '
        'was disabled. Await edenPrepareSelectableRegionForWeb() before '
        'runApp(). This region defers its own SelectionArea until the disable '
        'lands, but any SelectionArea your app owns was just built with the '
        'old BrowserContextMenu.enabled value and will re-inflate its '
        'SelectionContainer on its next rebuild ("Null check operator used on '
        'a null value" in release builds).',
      );
    }
    return true;
  }());
}

/// Makes every piece of text in [child] drag-selectable and copyable, with no
/// per-widget change to the widgets inside it.
///
/// Plain [Text] under this region becomes selectable as-is — that is the whole
/// point, and it is test-proven (`eden_selectable_region_test.dart`, reproducing
/// `40-RESEARCH.md` Appendix A probe 4: one `SelectionArea` over two plain
/// `Text`s installs exactly one `SelectableRegion`).
///
/// On web it additionally calls `BrowserContextMenu.disableContextMenu()` once,
/// so Flutter's own "Copy" menu appears on right-click instead of the browser's
/// native menu. On every non-web platform that call is skipped entirely.
///
/// ## Web apps: await [edenPrepareSelectableRegionForWeb] before `runApp`
///
/// `BrowserContextMenu.disableContextMenu()` takes effect asynchronously, and
/// `SelectableRegion` builds a different, unkeyed subtree depending on whether
/// it has. Any `SelectableRegion` that is built before the flag flips and
/// rebuilt after it double-registers its `SelectionContainer` — "Null check
/// operator used on a null value" in release builds. Disable the menu before
/// the first frame:
///
/// ```dart
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await edenPrepareSelectableRegionForWeb(); // no-op off web
///   runApp(const MyApp());
/// }
/// ```
///
/// If the app does not, this widget protects its OWN region: on web, until the
/// disable has completed, it builds [child] with no `SelectionArea` (text is
/// briefly not selectable), then installs one — moving [child] rather than
/// re-creating it, so the subtree's State survives. In debug it prints a
/// one-time warning naming [edenPrepareSelectableRegionForWeb]. What it cannot
/// do is protect a `SelectionArea` the APP owns (for example one wrapped around
/// its shell): that one was already built with the old flag value.
///
/// ## Opting a subtree OUT of selection
///
/// Interactive subtrees — buttons, menus, inline row actions — should not
/// participate in text selection, or a drag across the surface will swallow
/// their labels. Wrap them in `SelectionContainer.disabled`
/// (`widgets/selection_container.dart:65`), which is the documented opt-out:
///
/// ```dart
/// EdenSelectableRegion(
///   child: Column(
///     children: <Widget>[
///       const Text('this text is selectable'),
///       SelectionContainer.disabled(
///         child: TextButton(onPressed: doThing, child: const Text('Action')),
///       ),
///     ],
///   ),
/// )
/// ```
///
/// ## Consumer apps that do not use the Eden layouts
///
/// The Eden layouts bake this in for you. An app with its own page scaffolding
/// can install one region for the whole app via `MaterialApp.builder`:
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => EdenSelectableRegion(child: child ?? const SizedBox.shrink()),
///   home: MyHomePage(),
/// )
/// ```
///
/// ## Nesting collapses instead of fragmenting
///
/// Objective 040 installs this widget at more than one level ON PURPOSE — the
/// Eden layouts wrap `body`, the Eden pages wrap their content, and the
/// `MaterialApp.builder` recipe above wraps the whole app — so nesting is the
/// DEFAULT, not an edge case.
///
/// Two raw `SelectionArea`s nested inside each other are two SEPARATE selection
/// scopes: a drag begun in the outer one stops dead at the inner one's boundary,
/// so "select the whole page" would silently break exactly where more selection
/// was added. To prevent that, a *plain* nested [EdenSelectableRegion] — one
/// with no [contextMenuBuilder], [onSelectionChanged] or [focusNode] — detects
/// the ancestor region and becomes a no-op, leaving a single scope that spans
/// everything.
///
/// A *configured* nested region is still honoured and does open its own scope,
/// because that is an explicit request: silently discarding a caller's
/// [contextMenuBuilder] would be worse than the extra scope.
///
/// ## Tables need TSV copy as well
///
/// `SelectionArea` concatenates the selected fragments in tree order with NO
/// tab or newline between cells, so drag-copying a table yields run-together
/// text. Tabular surfaces need an explicit TSV copy action *in addition to*
/// this region — that is not something this widget can fix.
class EdenSelectableRegion extends StatefulWidget {
  /// Creates a selectable region around [child].
  const EdenSelectableRegion({
    super.key,
    required this.child,
    this.enabled = true,
    this.onSelectionChanged,
    this.disableBrowserContextMenu = true,
    this.focusNode,
    this.contextMenuBuilder,
  });

  /// The subtree whose text becomes selectable.
  final Widget child;

  /// When false this is a pass-through — [child] is returned untouched and no
  /// `SelectionArea` is installed.
  ///
  /// Escape hatch for a surface that must not be selectable at all. To exclude
  /// only *part* of a surface, use `SelectionContainer.disabled` instead.
  final bool enabled;

  /// Plain-text-only selection notifications.
  ///
  /// Flutter's newer selection-listener widget does NOT exist at the
  /// `>=3.27.0` floor; this is the entire available surface.
  /// [SelectedContent] carries plain text only — no
  /// offsets, no rich content. Do not build an API on top of this that implies
  /// otherwise.
  final ValueChanged<SelectedContent?>? onSelectionChanged;

  /// Whether to call `BrowserContextMenu.disableContextMenu()` on web so that
  /// Flutter's context menu, rather than the browser's, appears on right-click.
  ///
  /// Ignored on non-web platforms. The call is made at most once per process
  /// however many regions are mounted, and not at all if
  /// [edenPrepareSelectableRegionForWeb] already completed.
  ///
  /// When false this region neither issues the call nor waits for it, so on
  /// web it builds its `SelectionArea` at once — and is exposed to the flag
  /// flip if anything else disables the menu later.
  final bool disableBrowserContextMenu;

  /// Focus node forwarded to the underlying `SelectionArea`.
  final FocusNode? focusNode;

  /// Leave null to keep `SelectionArea`'s Material default
  /// (`material/selection_area.dart:54`).
  ///
  /// A null value is NOT forwarded — forwarding it would replace that default
  /// with "no menu at all".
  final SelectableRegionContextMenuBuilder? contextMenuBuilder;

  @override
  State<EdenSelectableRegion> createState() => _EdenSelectableRegionState();
}

class _EdenSelectableRegionState extends State<EdenSelectableRegion> {
  /// Web only, and only when this region had to WAIT for the context-menu
  /// disable (the app did not await [edenPrepareSelectableRegionForWeb] before
  /// `runApp`). Keys [EdenSelectableRegion.child] in both phases so that
  /// installing the `SelectionArea` above it MOVES the subtree instead of
  /// re-creating it: the child's State survives the switch.
  ///
  /// Null on every non-web platform and on web once the app prepared, which
  /// keeps those builds exactly what they were before this field existed.
  GlobalKey? _deferredChildKey;

  /// True while the disable this region is waiting for is still in flight.
  bool _awaitingContextMenuDisable = false;

  @override
  void initState() {
    super.initState();
    if (_takeWebPath && widget.enabled && widget.disableBrowserContextMenu) {
      final Future<void>? pending = _ensureBrowserContextMenuDisabled();
      if (pending != null) {
        _debugWarnUnpreparedRegion();
        _deferredChildKey = GlobalKey(debugLabel: 'EdenSelectableRegion.child');
        _awaitingContextMenuDisable = true;
        // Never errors (see _ensureBrowserContextMenuDisabled). On a failed
        // attempt the flag is still true, so installing now cannot flip.
        pending.then((_) {
          if (mounted) {
            setState(() => _awaitingContextMenuDisable = false);
          }
        });
      }
    }
  }

  /// True when this region carries no caller-specific configuration — i.e. it
  /// is a bare "make this subtree selectable" wrapper rather than a deliberate
  /// nested scope with its own menu, focus or change callback.
  bool get _isPlainWrapper =>
      widget.contextMenuBuilder == null &&
      widget.onSelectionChanged == null &&
      widget.focusNode == null;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    // Objective 040 bakes this widget in at MORE THAN ONE level by design:
    // EdenDesktopLayout/EdenMobileLayout wrap `body`, the Eden pages wrap their
    // own content, and the documented MaterialApp.builder recipe wraps the whole
    // app. Nesting is therefore the DEFAULT outcome, not an edge case.
    //
    // Two nested SelectionAreas are two SEPARATE selection scopes: a drag begun
    // in the outer one stops dead at the inner one's boundary, so "select the
    // whole page" silently stops working exactly where we added more selection.
    //
    // So a PLAIN inner wrapper defers to the ancestor and becomes a no-op. A
    // configured one (custom menu / focus node / change callback) is honoured,
    // because that is an explicit request for a distinct scope — silently
    // dropping a caller's contextMenuBuilder would be worse than the nesting.
    final hasAncestor =
        context.dependOnInheritedWidgetOfExactType<_EdenSelectionScope>() != null;
    if (hasAncestor && _isPlainWrapper) {
      return widget.child;
    }

    final GlobalKey? deferredChildKey = _deferredChildKey;
    final Widget child = deferredChildKey == null
        ? widget.child
        : KeyedSubtree(key: deferredChildKey, child: widget.child);

    // Web, app did not prepare, disable still in flight: build NO
    // SelectionArea yet. A SelectableRegion built now would see
    // BrowserContextMenu.enabled == true, and its next rebuild after the flip
    // would re-inflate and double-register its SelectionContainer. The scope is
    // still provided so plain nested regions are no-ops both before and after
    // the SelectionArea arrives.
    if (_awaitingContextMenuDisable) {
      return _EdenSelectionScope(child: child);
    }

    // `contextMenuBuilder` is forwarded ONLY when non-null so that
    // `SelectionArea`'s own Material default survives a null here.
    final Widget area = widget.contextMenuBuilder == null
        ? SelectionArea(
            focusNode: widget.focusNode,
            onSelectionChanged: widget.onSelectionChanged,
            child: child,
          )
        : SelectionArea(
            focusNode: widget.focusNode,
            onSelectionChanged: widget.onSelectionChanged,
            contextMenuBuilder: widget.contextMenuBuilder,
            child: child,
          );

    return _EdenSelectionScope(child: area);
  }
}

/// Marks that an [EdenSelectableRegion] is already active above this point in
/// the tree, so a plain nested one can defer to it instead of opening a second,
/// disjoint selection scope.
///
/// Private on purpose: this is an implementation detail of how Objective 040
/// makes "selection on by default at several layers" compose. Callers control
/// nesting through [EdenSelectableRegion.enabled] or `SelectionContainer.disabled`.
class _EdenSelectionScope extends InheritedWidget {
  const _EdenSelectionScope({required super.child});

  @override
  bool updateShouldNotify(_EdenSelectionScope oldWidget) => false;
}
