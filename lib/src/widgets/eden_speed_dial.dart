import 'package:flutter/material.dart';

/// An action item for [EdenSpeedDial].
class EdenSpeedDialAction {
  const EdenSpeedDialAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.backgroundColor,
    this.foregroundColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? foregroundColor;
}

/// Floating action button with expandable sub-actions.
///
/// Tapping the main FAB reveals a vertical list of labeled action buttons.
/// Tapping outside or on an action collapses the menu.
///
/// ```dart
/// EdenSpeedDial(
///   icon: Icons.add,
///   actions: [
///     EdenSpeedDialAction(icon: Icons.event, label: 'New Appointment', onTap: createAppointment),
///     EdenSpeedDialAction(icon: Icons.receipt, label: 'New Bid', onTap: createBid),
///     EdenSpeedDialAction(icon: Icons.build, label: 'New Request', onTap: createRequest),
///   ],
/// )
/// ```
class EdenSpeedDial extends StatefulWidget {
  const EdenSpeedDial({
    super.key,
    required this.actions,
    this.icon = Icons.add,
    this.activeIcon = Icons.close,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
  });

  final List<EdenSpeedDialAction> actions;
  final IconData icon;
  final IconData activeIcon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  State<EdenSpeedDial> createState() => _EdenSpeedDialState();
}

class _EdenSpeedDialState extends State<EdenSpeedDial>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _close() {
    setState(() {
      _isOpen = false;
      _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Action items
        if (_isOpen) ...[
          for (int i = widget.actions.length - 1; i >= 0; i--)
            _buildAction(context, widget.actions[i], i),
          const SizedBox(height: 8),
        ],
        // Main FAB
        FloatingActionButton(
          onPressed: _toggle,
          tooltip: widget.tooltip,
          backgroundColor:
              widget.backgroundColor ?? theme.colorScheme.primary,
          foregroundColor:
              widget.foregroundColor ?? theme.colorScheme.onPrimary,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) =>
                RotationTransition(turns: animation, child: child),
            child: Icon(
              _isOpen ? widget.activeIcon : widget.icon,
              key: ValueKey(_isOpen),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAction(
      BuildContext context, EdenSpeedDialAction action, int index) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label chip
          Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(6),
            color: theme.colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                action.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Mini FAB
          FloatingActionButton.small(
            heroTag: 'speed_dial_$index',
            onPressed: () {
              _close();
              action.onTap();
            },
            backgroundColor:
                action.backgroundColor ?? theme.colorScheme.secondaryContainer,
            foregroundColor: action.foregroundColor ??
                theme.colorScheme.onSecondaryContainer,
            child: Icon(action.icon, size: 20),
          ),
        ],
      ),
    );
  }
}
