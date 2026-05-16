import 'package:flutter/material.dart';

import 'eden_app_mode.dart';

/// Always-on mode-toggle escape hatch per
/// `.planning/COMPANION_UX_PATTERNS_2026-05-15.md` §0 lock A.
///
/// Donor: trades-react `client/src/components/layout/UXModeToggle.tsx`.
/// 3-state: admin / fieldCompanion / askUser. Donor uses
/// desktop / mobile / auto vocabulary — same semantics, renamed for
/// Eden.
///
/// Ships two variants:
///   - [EdenUxModeToggle.compact] — icon-only, fits in the companion
///     bottom-nav / `AppBar.actions` slot. ~132pt horizontal footprint.
///   - [EdenUxModeToggle.labeled] — icon + short label, fits in admin
///     top-bar slot. ~240pt horizontal footprint.
///
/// Wiring contract: tapping calls `controller.setMode(target)`. Either
/// pass a [EdenAppModeController] via the [controller] arg OR wrap in
/// an [EdenAppModeScope] so the toggle can read one from the tree.
/// Asserts at runtime if neither is supplied.
///
/// Gating ("only show on tablet + large mobile" from the donor's
/// `canToggleUX`) is the CONSUMER's responsibility — the library ships
/// the widget unconditionally and the consumer decides when to mount it.
class EdenUxModeToggle extends StatelessWidget {
  const EdenUxModeToggle._({
    super.key,
    this.controller,
    required _Variant variant,
  }) : _variant = variant;

  /// Icon-only variant — three 44pt tap targets in a Row.
  factory EdenUxModeToggle.compact({
    Key? key,
    EdenAppModeController? controller,
  }) =>
      EdenUxModeToggle._(
        key: key,
        controller: controller,
        variant: _Variant.compact,
      );

  /// Icon + short-label variant — three rows of icon + 'Field' /
  /// 'Admin' / 'Auto' text.
  factory EdenUxModeToggle.labeled({
    Key? key,
    EdenAppModeController? controller,
  }) =>
      EdenUxModeToggle._(
        key: key,
        controller: controller,
        variant: _Variant.labeled,
      );

  final EdenAppModeController? controller;
  final _Variant _variant;

  @override
  Widget build(BuildContext context) {
    final resolved = controller ?? EdenAppModeScope.maybeOf(context);
    assert(
      resolved != null,
      'EdenUxModeToggle requires either a controller arg or an EdenAppModeScope ancestor.',
    );
    // Rebuild when controller mutates without depending on the scope
    // (the scope rebuilds via InheritedNotifier; this widget rebuilds
    // even when an explicit controller arg is used).
    return AnimatedBuilder(
      animation: resolved!,
      builder: (context, _) => _buildOptions(context, resolved),
    );
  }

  Widget _buildOptions(BuildContext context, EdenAppModeController c) {
    const options = <EdenAppMode>[
      EdenAppMode.fieldCompanion,
      EdenAppMode.admin,
      EdenAppMode.askUser,
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final mode in options) _buildOption(context, c, mode),
      ],
    );
  }

  Widget _buildOption(
    BuildContext context,
    EdenAppModeController c,
    EdenAppMode mode,
  ) {
    final theme = Theme.of(context);
    final isActive = c.currentMode == mode;
    final bg = isActive
        ? theme.colorScheme.primaryContainer
        : Colors.transparent;
    final fg = isActive
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;

    return Tooltip(
      message: _tooltipFor(mode),
      child: Semantics(
        selected: isActive,
        button: true,
        label: _labelFor(mode),
        child: InkWell(
          onTap: () => c.setMode(mode),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: _variant == _Variant.compact
                ? Icon(_iconFor(mode), color: fg)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_iconFor(mode), color: fg),
                      const SizedBox(width: 6),
                      Text(_labelFor(mode), style: TextStyle(color: fg)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(EdenAppMode mode) {
    switch (mode) {
      case EdenAppMode.fieldCompanion:
        return Icons.smartphone;
      case EdenAppMode.admin:
        return Icons.desktop_windows;
      case EdenAppMode.askUser:
        return Icons.auto_awesome;
    }
  }

  String _labelFor(EdenAppMode mode) {
    switch (mode) {
      case EdenAppMode.fieldCompanion:
        return 'Field';
      case EdenAppMode.admin:
        return 'Admin';
      case EdenAppMode.askUser:
        return 'Auto';
    }
  }

  String _tooltipFor(EdenAppMode mode) {
    switch (mode) {
      case EdenAppMode.fieldCompanion:
        return 'Field companion';
      case EdenAppMode.admin:
        return 'Admin (desktop view)';
      case EdenAppMode.askUser:
        return 'Auto (resize-driven)';
    }
  }
}

enum _Variant { compact, labeled }
