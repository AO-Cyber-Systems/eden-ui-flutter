import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import 'permission_matrix/matrix_cells.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

/// A single permission entry in the matrix.
class EdenPermission {
  /// Creates a permission.
  const EdenPermission({
    required this.id,
    required this.label,
    this.description = '',
    required this.category,
  });

  /// Unique identifier.
  final String id;

  /// Human-readable label shown in the row.
  final String label;

  /// Optional description shown as a tooltip.
  final String description;

  /// Category/group key used to cluster permissions.
  final String category;
}

/// A role column in the matrix.
class EdenRole {
  /// Creates a role.
  const EdenRole({
    required this.id,
    required this.name,
    this.color,
    this.permissions = const {},
  });

  /// Unique identifier.
  final String id;

  /// Display name shown in the column header.
  final String name;

  /// Optional accent color for this role's column.
  final Color? color;

  /// Set of granted permission ids.
  final Set<String> permissions;

  /// Returns a copy with the given permission toggled.
  EdenRole copyWithPermission(String permissionId, bool granted) {
    final next = Set<String>.from(permissions);
    if (granted) {
      next.add(permissionId);
    } else {
      next.remove(permissionId);
    }
    return EdenRole(
      id: id,
      name: name,
      color: color,
      permissions: next,
    );
  }
}

/// Visual state for a single matrix cell.
enum EdenPermissionCellState {
  /// Permission is explicitly granted.
  granted,

  /// Permission is not granted.
  denied,

  /// Permission is inherited / partially granted (shown as a dash).
  inherited,
}

/// Callback signature for a single permission toggle.
typedef PermissionToggleCallback = void Function(
  String roleId,
  String permissionId,
  bool granted,
);

/// Callback signature for bulk changes on a category.
typedef BulkChangeCallback = void Function(
  String roleId,
  String category,
  bool granted,
);

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

/// A permission matrix editor for role-based access control.
///
/// Displays a grid where rows are permissions (grouped by category) and
/// columns are roles. Each cell can be tapped to toggle the permission.
class EdenPermissionMatrix extends StatefulWidget {
  /// Creates a permission matrix.
  const EdenPermissionMatrix({
    super.key,
    required this.permissions,
    required this.roles,
    this.inheritedPermissions,
    this.changedCells,
    this.onPermissionToggled,
    this.onBulkChange,
    this.readOnly = false,
    this.cellStateOverrides,
  });

  /// All permissions to display as rows.
  final List<EdenPermission> permissions;

  /// All roles to display as columns.
  final List<EdenRole> roles;

  /// Optional map of inherited permission ids per role. These display as a
  /// dash rather than empty.
  final Map<String, Set<String>>? inheritedPermissions;

  /// Optional set of (roleId, permissionId) tuples that should be highlighted
  /// as changed.
  final Set<(String roleId, String permissionId)>? changedCells;

  /// Called when a single cell is toggled.
  final PermissionToggleCallback? onPermissionToggled;

  /// Called when select-all / deselect-all is used on a category.
  final BulkChangeCallback? onBulkChange;

  /// When true, the matrix is view-only (taps are disabled).
  final bool readOnly;

  /// Optional per-cell state override map keyed by (roleId, permissionId).
  final Map<(String, String), EdenPermissionCellState>? cellStateOverrides;

  @override
  State<EdenPermissionMatrix> createState() => _EdenPermissionMatrixState();
}

class _EdenPermissionMatrixState extends State<EdenPermissionMatrix> {
  String _searchQuery = '';
  final Set<String> _collapsedCategories = {};

  // ---------------------------------------------------------------------------
  // Derived data
  // ---------------------------------------------------------------------------

  /// Categories in order of first appearance.
  List<String> get _categories {
    final seen = <String>{};
    final result = <String>[];
    for (final p in widget.permissions) {
      if (seen.add(p.category)) result.add(p.category);
    }
    return result;
  }

  List<EdenPermission> _filteredPermissions(String category) {
    return widget.permissions.where((p) {
      if (p.category != category) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return p.label.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q);
    }).toList();
  }

  EdenPermissionCellState _cellState(EdenRole role, EdenPermission perm) {
    final override = widget.cellStateOverrides?[(role.id, perm.id)];
    if (override != null) return override;
    if (role.permissions.contains(perm.id)) {
      return EdenPermissionCellState.granted;
    }
    if (widget.inheritedPermissions?[role.id]?.contains(perm.id) ?? false) {
      return EdenPermissionCellState.inherited;
    }
    return EdenPermissionCellState.denied;
  }

  bool _isCategoryFullyGranted(String category, EdenRole role) {
    final perms = widget.permissions.where((p) => p.category == category);
    return perms.every((p) => role.permissions.contains(p.id));
  }

  bool _isChanged(String roleId, String permissionId) {
    return widget.changedCells?.contains((roleId, permissionId)) ?? false;
  }

  // ---------------------------------------------------------------------------
  // Layout constants
  // ---------------------------------------------------------------------------

  static const double _labelColumnWidth = 220;
  static const double _cellWidth = 100;
  static const double _cellHeight = 40;
  static const double _headerHeight = 56;

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categories = _categories;
    final borderColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.hasBoundedHeight;
        final matrix = _buildMatrix(theme, isDark, categories, borderColor);
        final wrappedMatrix = hasBoundedHeight
            ? Expanded(child: matrix)
            : matrix;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: hasBoundedHeight ? MainAxisSize.max : MainAxisSize.min,
          children: [
            // Search bar
            _buildSearchBar(theme, isDark),
            const SizedBox(height: EdenSpacing.space3),
            // Matrix
            wrappedMatrix,
          ],
        );
      },
    );
  }

  Widget _buildSearchBar(ThemeData theme, bool isDark) {
    return SizedBox(
      height: 40,
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: TextStyle(
          fontSize: 14,
          color: theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: 'Search permissions...',
          hintStyle: TextStyle(
            fontSize: 14,
            color: isDark ? EdenColors.neutral[500] : EdenColors.neutral[400],
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 18,
            color: isDark ? EdenColors.neutral[500] : EdenColors.neutral[400],
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: EdenSpacing.space3,
          ),
          border: OutlineInputBorder(
            borderRadius: EdenRadii.borderRadiusMd,
            borderSide: BorderSide(
              color:
                  isDark ? EdenColors.neutral[700]! : EdenColors.neutral[300]!,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: EdenRadii.borderRadiusMd,
            borderSide: BorderSide(
              color:
                  isDark ? EdenColors.neutral[700]! : EdenColors.neutral[300]!,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: EdenRadii.borderRadiusMd,
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
            ),
          ),
          filled: true,
          fillColor:
              isDark ? EdenColors.neutral[800] : EdenColors.neutral[50],
        ),
      ),
    );
  }

  Widget _buildMatrix(
    ThemeData theme,
    bool isDark,
    List<String> categories,
    Color borderColor,
  ) {
    // Build flat list of row widgets: category headers + permission rows.
    final rows = <Widget>[];
    for (final category in categories) {
      final perms = _filteredPermissions(category);
      if (perms.isEmpty) continue;
      final collapsed = _collapsedCategories.contains(category);

      rows.add(
        CategoryHeaderRow(
          category: category,
          roles: widget.roles,
          collapsed: collapsed,
          isDark: isDark,
          theme: theme,
          borderColor: borderColor,
          labelWidth: _labelColumnWidth,
          cellWidth: _cellWidth,
          cellHeight: _cellHeight,
          readOnly: widget.readOnly,
          isFullyGranted: (role) => _isCategoryFullyGranted(category, role),
          onToggleCollapse: () {
            setState(() {
              if (collapsed) {
                _collapsedCategories.remove(category);
              } else {
                _collapsedCategories.add(category);
              }
            });
          },
          onSelectAll: (role, granted) {
            widget.onBulkChange?.call(role.id, category, granted);
          },
        ),
      );

      if (!collapsed) {
        for (final perm in perms) {
          rows.add(
            PermissionRow(
              permission: perm,
              roles: widget.roles,
              isDark: isDark,
              theme: theme,
              borderColor: borderColor,
              labelWidth: _labelColumnWidth,
              cellWidth: _cellWidth,
              cellHeight: _cellHeight,
              readOnly: widget.readOnly,
              cellState: (role) => _cellState(role, perm),
              isChanged: (roleId) => _isChanged(roleId, perm.id),
              onToggle: (role) {
                final current = _cellState(role, perm);
                final granted = current != EdenPermissionCellState.granted;
                widget.onPermissionToggled?.call(role.id, perm.id, granted);
              },
            ),
          );
        }
      }
    }

    if (rows.isEmpty) {
      return Center(
        child: Text(
          'No permissions match your search.',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? EdenColors.neutral[400] : EdenColors.neutral[500],
          ),
        ),
      );
    }

    // Use a two-axis scroll view: horizontal scroll for roles, vertical for
    // permissions. The label column and header row are sticky.
    final totalRoleWidth = widget.roles.length * _cellWidth;

    return LayoutBuilder(
      builder: (context, constraints) {
        final innerBounded = constraints.hasBoundedHeight;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: _labelColumnWidth + totalRoleWidth,
            child: Column(
              mainAxisSize: innerBounded ? MainAxisSize.max : MainAxisSize.min,
              children: [
                // Sticky header row
                RoleHeaderRow(
                  roles: widget.roles,
                  isDark: isDark,
                  theme: theme,
                  borderColor: borderColor,
                  labelWidth: _labelColumnWidth,
                  cellWidth: _cellWidth,
                  headerHeight: _headerHeight,
                ),
                Divider(height: 1, color: borderColor),
                // Scrollable body
                if (innerBounded)
                  Expanded(
                    child: ListView(
                      children: rows,
                    ),
                  )
                else
                  ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: rows,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

