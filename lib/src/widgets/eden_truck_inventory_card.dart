import 'package:flutter/material.dart';

import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import 'eden_stock_level_indicator.dart';

/// Generic value class for [EdenTruckInventoryCard]. Consumer maps domain
/// rows (`truck_inventories` for fuel delivery; delivery van capacities for
/// service trucks; tanker capacities for chemical / beverage logistics) to
/// this class.
@immutable
class EdenTruckInventoryData {
  const EdenTruckInventoryData({
    required this.truckLabel,
    required this.fuelTypeLabel,
    required this.capacityGal,
    required this.currentGal,
  });

  final String truckLabel;
  final String fuelTypeLabel;
  final double capacityGal;
  final double currentGal;

  /// Clamped fill ratio in `[0.0, 1.0]`. Defensive against zero capacity.
  double get fillRatio {
    if (capacityGal <= 0) return 0.0;
    final r = currentGal / capacityGal;
    if (r < 0) return 0.0;
    if (r > 1.0) return 1.0;
    return r;
  }

  bool get isOverfull => capacityGal > 0 && currentGal > capacityGal;
}

/// Per-truck capacity + current load + fuel-type card.
///
/// Composes [EdenStockLevelIndicator] for the fill bar. Generic — donor was
/// `trades-flutter/lib/features/fleet/presentation/widgets/truck_inventory_section.dart`
/// (Flutter port, Riverpod-stripped, made generic). Multi-item inventory is
/// out of scope (consumer composes multiple cards in a grid).
///
/// Responsive: 4-row vertical layout at width < 500pt; 2-column horizontal
/// at ≥ 500pt.
///
/// Pre-computes a 0-100 fill percent and passes it as `currentStock` with
/// `reorderPoint: 0` to the indicator — treats it as a percent gauge on the
/// indicator's internal `maxCapacity = 100` fallback.
class EdenTruckInventoryCard extends StatelessWidget {
  const EdenTruckInventoryCard({
    super.key,
    required this.data,
    this.onTap,
  });

  final EdenTruckInventoryData data;
  final VoidCallback? onTap;

  static String _fmt(double v) {
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  String get _capacityLabel {
    if (data.capacityGal <= 0) return '— / 0 gal';
    return '${_fmt(data.currentGal)}/${_fmt(data.capacityGal)} gal';
  }

  int get _percentInt => (data.fillRatio * 100).round();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = Container(
      padding: const EdgeInsets.all(EdenSpacing.space3),
      decoration: BoxDecoration(
        borderRadius: EdenRadii.borderRadiusMd,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 500;
          final left = _LeftColumn(data: data);
          final right = _RightColumn(
            capacityLabel: _capacityLabel,
            percentInt: _percentInt,
            isOverfull: data.isOverfull,
          );
          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: left),
                const SizedBox(width: 12),
                Expanded(child: right),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              left,
              const SizedBox(height: 12),
              right,
            ],
          );
        },
      ),
    );
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: EdenRadii.borderRadiusMd,
      child: card,
    );
  }
}

class _LeftColumn extends StatelessWidget {
  const _LeftColumn({required this.data});

  final EdenTruckInventoryData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                data.truckLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Chip(
          label: Text(
            data.fuelTypeLabel,
            style: const TextStyle(fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          backgroundColor: theme.colorScheme.secondaryContainer,
        ),
      ],
    );
  }
}

class _RightColumn extends StatelessWidget {
  const _RightColumn({
    required this.capacityLabel,
    required this.percentInt,
    required this.isOverfull,
  });

  final String capacityLabel;
  final int percentInt;
  final bool isOverfull;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                '$capacityLabel  •  $percentInt%',
                style: theme.textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isOverfull) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Overfull',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        EdenStockLevelIndicator(
          currentStock: percentInt,
          reorderPoint: 0,
          showLabel: false,
        ),
      ],
    );
  }
}
