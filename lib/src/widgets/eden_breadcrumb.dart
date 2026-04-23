import 'package:flutter/material.dart';

/// A single breadcrumb item.
class EdenBreadcrumbItem {
  const EdenBreadcrumbItem({
    required this.label,
    this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
}

/// Mirrors the eden_breadcrumb Rails component.
class EdenBreadcrumb extends StatelessWidget {
  const EdenBreadcrumb({
    super.key,
    required this.items,
  });

  final List<EdenBreadcrumbItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.chevron_right, size: 16, color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
            _BreadcrumbChip(
              item: items[i],
              isCurrent: i == items.length - 1,
            ),
          ],
        ],
      ),
    );
  }
}

class _BreadcrumbChip extends StatelessWidget {
  const _BreadcrumbChip({required this.item, required this.isCurrent});

  final EdenBreadcrumbItem item;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isCurrent
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.onSurface;

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.icon != null) ...[
          Icon(item.icon, size: 14, color: color),
          const SizedBox(width: 4),
        ],
        Text(
          item.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isCurrent ? FontWeight.w500 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );

    if (isCurrent || item.onTap == null) return child;

    return Semantics(
      button: true,
      label: item.label,
      child: GestureDetector(onTap: item.onTap, child: child),
    );
  }
}
