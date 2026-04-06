import 'package:flutter/material.dart';
import '../../tokens/colors.dart';
import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';
import '../eden_permission_matrix.dart';

class RoleHeaderRow extends StatelessWidget {
  const RoleHeaderRow({
    required this.roles,
    required this.isDark,
    required this.theme,
    required this.borderColor,
    required this.labelWidth,
    required this.cellWidth,
    required this.headerHeight,
  });

  final List<EdenRole> roles;
  final bool isDark;
  final ThemeData theme;
  final Color borderColor;
  final double labelWidth;
  final double cellWidth;
  final double headerHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: headerHeight,
      child: Row(
        children: [
          // Empty top-left corner
          SizedBox(
            width: labelWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: EdenSpacing.space3,
              ),
              child: Text(
                'Permission',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? EdenColors.neutral[400]
                      : EdenColors.neutral[500],
                ),
              ),
            ),
          ),
          // Role headers
          for (final role in roles)
            SizedBox(
              width: cellWidth,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: role.color ?? theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category header row
// ---------------------------------------------------------------------------

class CategoryHeaderRow extends StatelessWidget {
  const CategoryHeaderRow({
    required this.category,
    required this.roles,
    required this.collapsed,
    required this.isDark,
    required this.theme,
    required this.borderColor,
    required this.labelWidth,
    required this.cellWidth,
    required this.cellHeight,
    required this.readOnly,
    required this.isFullyGranted,
    required this.onToggleCollapse,
    required this.onSelectAll,
  });

  final String category;
  final List<EdenRole> roles;
  final bool collapsed;
  final bool isDark;
  final ThemeData theme;
  final Color borderColor;
  final double labelWidth;
  final double cellWidth;
  final double cellHeight;
  final bool readOnly;
  final bool Function(EdenRole role) isFullyGranted;
  final VoidCallback onToggleCollapse;
  final void Function(EdenRole role, bool granted) onSelectAll;

  @override
  Widget build(BuildContext context) {
    final bgColor =
        isDark ? EdenColors.neutral[850] : EdenColors.neutral[100];

    return Container(
      height: cellHeight,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          // Category label with collapse toggle
          SizedBox(
            width: labelWidth,
            child: Semantics(
              button: true,
              label: '${collapsed ? 'Expand' : 'Collapse'} $category',
              child: InkWell(
                onTap: onToggleCollapse,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: EdenSpacing.space3,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        collapsed
                            ? Icons.chevron_right
                            : Icons.expand_more,
                        size: 18,
                        color: isDark
                            ? EdenColors.neutral[400]
                            : EdenColors.neutral[500],
                      ),
                      const SizedBox(width: EdenSpacing.space1),
                      Expanded(
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Per-role select/deselect all toggle
          for (final role in roles)
            SizedBox(
              width: cellWidth,
              child: Center(
                child: readOnly
                    ? const SizedBox.shrink()
                    : CategoryToggleButton(
                        allGranted: isFullyGranted(role),
                        roleColor: role.color ?? theme.colorScheme.primary,
                        onTap: () =>
                            onSelectAll(role, !isFullyGranted(role)),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

class CategoryToggleButton extends StatelessWidget {
  const CategoryToggleButton({
    required this.allGranted,
    required this.roleColor,
    required this.onTap,
  });

  final bool allGranted;
  final Color roleColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: allGranted ? 'Deselect all permissions' : 'Select all permissions',
      child: Tooltip(
        message: allGranted ? 'Deselect all' : 'Select all',
        child: InkWell(
          borderRadius: EdenRadii.borderRadiusSm,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              allGranted ? 'Clear' : 'All',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: roleColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Permission row
// ---------------------------------------------------------------------------

class PermissionRow extends StatelessWidget {
  const PermissionRow({
    required this.permission,
    required this.roles,
    required this.isDark,
    required this.theme,
    required this.borderColor,
    required this.labelWidth,
    required this.cellWidth,
    required this.cellHeight,
    required this.readOnly,
    required this.cellState,
    required this.isChanged,
    required this.onToggle,
  });

  final EdenPermission permission;
  final List<EdenRole> roles;
  final bool isDark;
  final ThemeData theme;
  final Color borderColor;
  final double labelWidth;
  final double cellWidth;
  final double cellHeight;
  final bool readOnly;
  final EdenPermissionCellState Function(EdenRole role) cellState;
  final bool Function(String roleId) isChanged;
  final void Function(EdenRole role) onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: cellHeight,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          // Permission label
          SizedBox(
            width: labelWidth,
            child: Padding(
              padding: const EdgeInsets.only(
                left: EdenSpacing.space8,
                right: EdenSpacing.space2,
              ),
              child: Tooltip(
                message: permission.description.isNotEmpty
                    ? permission.description
                    : permission.label,
                child: Text(
                  permission.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          // Cells
          for (final role in roles)
            PermissionCell(
              state: cellState(role),
              changed: isChanged(role.id),
              width: cellWidth,
              height: cellHeight,
              isDark: isDark,
              theme: theme,
              roleColor: role.color ?? theme.colorScheme.primary,
              readOnly: readOnly,
              onTap: () => onToggle(role),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Permission cell
// ---------------------------------------------------------------------------

class PermissionCell extends StatelessWidget {
  const PermissionCell({
    required this.state,
    required this.changed,
    required this.width,
    required this.height,
    required this.isDark,
    required this.theme,
    required this.roleColor,
    required this.readOnly,
    required this.onTap,
  });

  final EdenPermissionCellState state;
  final bool changed;
  final double width;
  final double height;
  final bool isDark;
  final ThemeData theme;
  final Color roleColor;
  final bool readOnly;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final changeBg = changed
        ? (isDark
            ? EdenColors.warning.withValues(alpha: 0.10)
            : EdenColors.warning.withValues(alpha: 0.08))
        : null;

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: changeBg ?? Colors.transparent,
        child: InkWell(
          onTap: readOnly ? null : onTap,
          child: Center(child: _buildIcon()),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    switch (state) {
      case EdenPermissionCellState.granted:
        return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: roleColor.withValues(alpha: 0.12),
            borderRadius: EdenRadii.borderRadiusSm,
          ),
          child: Icon(
            Icons.check,
            size: 16,
            color: roleColor,
          ),
        );
      case EdenPermissionCellState.inherited:
        return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isDark
                ? EdenColors.neutral[700]!.withValues(alpha: 0.5)
                : EdenColors.neutral[200]!.withValues(alpha: 0.7),
            borderRadius: EdenRadii.borderRadiusSm,
          ),
          child: Icon(
            Icons.remove,
            size: 14,
            color: isDark ? EdenColors.neutral[400] : EdenColors.neutral[500],
          ),
        );
      case EdenPermissionCellState.denied:
        return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark
                  ? EdenColors.neutral[700]!
                  : EdenColors.neutral[300]!,
            ),
            borderRadius: EdenRadii.borderRadiusSm,
          ),
        );
    }
  }
}
