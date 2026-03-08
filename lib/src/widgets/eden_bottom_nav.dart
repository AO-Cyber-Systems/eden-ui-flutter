import 'package:flutter/material.dart';
import '../tokens/colors.dart';

/// A single item in the bottom navigation.
class EdenBottomNavItem {
  const EdenBottomNavItem({
    required this.label,
    required this.icon,
    this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData? activeIcon;
}

/// Mirrors the eden_bottom_nav Rails component.
///
/// A fixed bottom navigation bar for mobile layouts.
class EdenBottomNav extends StatelessWidget {
  const EdenBottomNav({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<EdenBottomNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Row(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final isActive = i == selectedIndex;

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isActive ? (item.activeIcon ?? item.icon) : item.icon,
                    size: 22,
                    color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
