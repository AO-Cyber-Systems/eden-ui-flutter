import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Segmented button for light/dark/system theme selection.
class EdenThemeSelector extends StatelessWidget {
  const EdenThemeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? EdenColors.neutral[800] : EdenColors.neutral[100],
        borderRadius: EdenRadii.borderRadiusLg,
        border: Border.all(
          color: isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!,
        ),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Segment(
            icon: Icons.light_mode_outlined,
            label: 'Light',
            isSelected: value == ThemeMode.light,
            onTap: () => onChanged(ThemeMode.light),
            isDark: isDark,
            theme: theme,
          ),
          _Segment(
            icon: Icons.desktop_mac_outlined,
            label: 'System',
            isSelected: value == ThemeMode.system,
            onTap: () => onChanged(ThemeMode.system),
            isDark: isDark,
            theme: theme,
          ),
          _Segment(
            icon: Icons.dark_mode_outlined,
            label: 'Dark',
            isSelected: value == ThemeMode.dark,
            onTap: () => onChanged(ThemeMode.dark),
            isDark: isDark,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final selectedBg = isDark ? EdenColors.neutral[700]! : Colors.white;
    final selectedFg = isDark ? EdenColors.neutral[100]! : EdenColors.neutral[900]!;
    final unselectedFg = isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: EdenSpacing.space3,
          vertical: EdenSpacing.space1 + 2,
        ),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : Colors.transparent,
          borderRadius: EdenRadii.borderRadiusMd,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? selectedFg : unselectedFg,
            ),
            const SizedBox(width: EdenSpacing.space1),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? selectedFg : unselectedFg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
