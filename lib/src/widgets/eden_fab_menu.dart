import 'package:flutter/material.dart';
import '../tokens/springs.dart';

/// One action child inside an [EdenFabMenu].
class EdenFabAction {
  const EdenFabAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.tooltip,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final String? tooltip;
}

/// M3 Expressive FAB menu — floating action button with 2-6 expandable action
/// children that unfurl above the FAB with [EdenSprings.snap]-driven motion.
///
/// SIBLING (not replacement) of `EdenMobileAiFab` from obj 007 — that widget
/// stays as a specialized AI-chat launcher. [EdenFabMenu] is the cross-vertical
/// generic FAB menu primitive.
///
/// Usage:
/// ```dart
/// Scaffold(
///   floatingActionButton: EdenFabMenu(
///     primaryIcon: Icons.add,
///     actions: [
///       EdenFabAction(icon: Icons.work_outline, label: 'New Job', onPressed: _newJob),
///       EdenFabAction(icon: Icons.assignment_outlined, label: 'New Estimate', onPressed: _newEstimate),
///     ],
///   ),
/// )
/// ```
class EdenFabMenu extends StatefulWidget {
  const EdenFabMenu({
    super.key,
    required this.primaryIcon,
    required this.actions,
    this.closeIcon,
    this.accentColor,
    this.primaryTooltip,
    this.heroTag = 'eden_fab_menu',
  }) : assert(actions.length >= 1 && actions.length <= 6,
            'EdenFabMenu supports 1-6 actions.');

  final IconData primaryIcon;
  final List<EdenFabAction> actions;
  final IconData? closeIcon;
  final Color? accentColor;
  final String? primaryTooltip;
  final Object heroTag;

  @override
  State<EdenFabMenu> createState() => _EdenFabMenuState();
}

class _EdenFabMenuState extends State<EdenFabMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _menuController;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController.unbounded(vsync: this, value: 0.0);
  }

  @override
  void dispose() {
    _menuController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
    _menuController.animateWith(EdenSprings.simulationFor(
      EdenSprings.snap,
      from: _menuController.value,
      to: _isOpen ? 1.0 : 0.0,
    ));
  }

  void _close() {
    if (!_isOpen) return;
    setState(() => _isOpen = false);
    _menuController.animateWith(EdenSprings.simulationFor(
      EdenSprings.snap,
      from: _menuController.value,
      to: 0.0,
    ));
  }

  void _handleAction(int i) {
    widget.actions[i].onPressed();
    _close();
  }

  double _staggerValueFor(int i) {
    final start = i * 0.15;
    final v = ((_menuController.value - start) / (1.0 - start)).clamp(0.0, 1.0);
    return v;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = widget.accentColor ?? theme.colorScheme.primary;
    final closeIcon = widget.closeIcon ?? Icons.close;

    return AnimatedBuilder(
      animation: _menuController,
      builder: (context, _) {
        final menuV = _menuController.value;
        final showActions = _isOpen || menuV > 0.01;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Scrim (only active when open).
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !_isOpen,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _close,
                  child: const ColoredBox(color: Color(0x00000000)),
                ),
              ),
            ),
            // Action stack — only mounted while the menu is opening, open, or
            // closing (until value reaches 0). Removes opacity-0 labels from
            // the tree when fully closed so closed-state finds are clean.
            if (showActions)
              Positioned(
                right: 16,
                bottom: 80,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (int i = widget.actions.length - 1; i >= 0; i--)
                      _buildActionRow(theme, accent, i),
                  ],
                ),
              ),
            // Primary FAB.
            Positioned(
              right: 16,
              bottom: 16,
              child: Semantics(
                button: true,
                label: widget.primaryTooltip ?? 'Open menu',
                child: Tooltip(
                  message: widget.primaryTooltip ?? 'Open menu',
                  child: FloatingActionButton(
                    heroTag: widget.heroTag,
                    onPressed: _toggle,
                    backgroundColor: accent,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        _isOpen ? closeIcon : widget.primaryIcon,
                        key: ValueKey(_isOpen),
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionRow(ThemeData theme, Color accent, int i) {
    final v = _staggerValueFor(i);
    final action = widget.actions[i];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - v) * 20),
          child: IgnorePointer(
            ignoring: !_isOpen,
            child: Semantics(
              button: true,
              label: action.tooltip ?? action.label,
              container: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _handleAction(i),
                child: ExcludeSemantics(child: Tooltip(
                  message: action.tooltip ?? action.label,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 240),
                        child: Material(
                          elevation: 2,
                          borderRadius: BorderRadius.circular(6),
                          color: theme.colorScheme.surface,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Text(
                              action.label,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        elevation: 4,
                        shape: const CircleBorder(),
                        color: action.backgroundColor ?? accent,
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(action.icon, color: theme.colorScheme.onPrimary),
                        ),
                      ),
                    ],
                  ),
                )),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
