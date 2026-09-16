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
// Convention: forward-don't-reimplement, matching the other thin wrappers in
// this package.  `StatefulWidget` only because the one-shot web call belongs in
// `initState`, never in `build`.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// Library-private latch so nested or repeated [EdenSelectableRegion]s disable
/// the browser context menu exactly once per process.
///
/// `BrowserContextMenu.disableContextMenu()` is asynchronous and is not free to
/// re-issue; TRD 40-06 bakes this widget into both the Eden layouts and the
/// library pages, so a single app can easily mount several regions.
bool _browserContextMenuDisabled = false;

/// Fire-and-forget, idempotent web-only disable of the browser context menu.
///
/// Callers MUST already have checked [kIsWeb] — `disableContextMenu()` asserts
/// `kIsWeb` internally (`services/browser_context_menu.dart`).
void _disableBrowserContextMenuOnce() {
  if (_browserContextMenuDisabled) {
    return;
  }
  _browserContextMenuDisabled = true;
  unawaited(
    BrowserContextMenu.disableContextMenu().catchError((Object error) {
      // Let a later region retry rather than latching a failed attempt.
      _browserContextMenuDisabled = false;
      assert(() {
        debugPrint('EdenSelectableRegion: disableContextMenu() failed: $error');
        return true;
      }());
    }),
  );
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
  /// however many regions are mounted.
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
  @override
  void initState() {
    super.initState();
    if (kIsWeb && widget.enabled && widget.disableBrowserContextMenu) {
      _disableBrowserContextMenuOnce();
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

    // `contextMenuBuilder` is forwarded ONLY when non-null so that
    // `SelectionArea`'s own Material default survives a null here.
    final Widget area = widget.contextMenuBuilder == null
        ? SelectionArea(
            focusNode: widget.focusNode,
            onSelectionChanged: widget.onSelectionChanged,
            child: widget.child,
          )
        : SelectionArea(
            focusNode: widget.focusNode,
            onSelectionChanged: widget.onSelectionChanged,
            contextMenuBuilder: widget.contextMenuBuilder,
            child: widget.child,
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
