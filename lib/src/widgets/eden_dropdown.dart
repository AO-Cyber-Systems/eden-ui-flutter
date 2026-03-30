import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';

/// A single item in an [EdenDropdown].
class EdenDropdownItem {
  const EdenDropdownItem({
    required this.label,
    this.icon,
    this.destructive = false,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool destructive;
  final VoidCallback? onTap;
}

/// A divider entry for [EdenDropdown].
class EdenDropdownDivider extends EdenDropdownItem {
  const EdenDropdownDivider() : super(label: '');
}

/// Mirrors the eden_dropdown Rails component.
///
/// A popup menu attached to a trigger widget.
class EdenDropdown extends StatelessWidget {
  const EdenDropdown({
    super.key,
    required this.items,
    required this.child,
    this.offset = Offset.zero,
  });

  final List<EdenDropdownItem> items;
  final Widget child;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: () => _showMenu(context),
        child: child,
      ),
    );
  }

  void _showMenu(BuildContext context) {
    final theme = Theme.of(context);
    final RenderBox button = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset(0, button.size.height) + offset, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero) + offset, ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final entries = <PopupMenuEntry<int>>[];
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      if (item is EdenDropdownDivider) {
        entries.add(const PopupMenuDivider(height: 1));
      } else {
        entries.add(PopupMenuItem<int>(
          value: i,
          child: Row(
            children: [
              if (item.icon != null) ...[
                Icon(
                  item.icon,
                  size: 16,
                  color: item.destructive
                      ? EdenColors.error
                      : theme.colorScheme.onSurface,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 13,
                  color: item.destructive
                      ? EdenColors.error
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ));
      }
    }

    showMenu<int>(
      context: context,
      position: position,
      items: entries,
      shape: RoundedRectangleBorder(borderRadius: EdenRadii.borderRadiusLg),
      color: theme.colorScheme.surface,
      elevation: 8,
    ).then((index) {
      if (index != null && items[index].onTap != null) {
        items[index].onTap!();
      }
    });
  }
}
