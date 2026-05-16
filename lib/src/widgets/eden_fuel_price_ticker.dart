import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import 'eden_currency_display.dart';

/// Polarity for [EdenFuelPriceTicker] delta color coding.
///
/// `lowerIsBetter` (default) — common for buyer / heating-oil perspectives:
/// down delta is green (favorable), up delta is red (unfavorable).
///
/// `higherIsBetter` — common for seller / wholesale resale perspectives:
/// up delta is green, down is red.
enum EdenFuelPriceDeltaPolarity { lowerIsBetter, higherIsBetter }

/// Generic value class for [EdenFuelPriceTicker]. Consumer maps domain rows
/// (`fuel_prices` + per-tenant settings; or commodity / electricity / FX
/// pricing rows) to this class.
@immutable
class EdenFuelPriceData {
  const EdenFuelPriceData({
    required this.currentCents,
    required this.priorCents,
    required this.fuelTypeLabel,
    required this.asOf,
    this.currencyCode = 'USD',
  });

  final int currentCents;
  final int priorCents;
  final String fuelTypeLabel;
  final DateTime asOf;
  final String currencyCode;
}

/// Real-time price-tile primitive composing [EdenCurrencyDisplay] for the
/// primary price + a delta chip (since-prior) + as-of relative-time caption.
///
/// Generalizes to commodity tickers, electricity spot prices, FX tickers,
/// any market price display where "up = good or bad depending on
/// perspective" needs configurable polarity.
///
/// Live updates: the widget is dumb — consumer passes new [data] via
/// `setState`. No polling, no streaming, no animation transitions in v1.
class EdenFuelPriceTicker extends StatelessWidget {
  const EdenFuelPriceTicker({
    super.key,
    required this.data,
    this.deltaPolarity = EdenFuelPriceDeltaPolarity.lowerIsBetter,
    this.now,
  });

  final EdenFuelPriceData data;
  final EdenFuelPriceDeltaPolarity deltaPolarity;

  /// Optional override for the "current time" used in relative-time
  /// formatting. Tests inject this for deterministic assertions. Defaults
  /// to `DateTime.now()` when null.
  final DateTime? now;

  int get _deltaCents => data.currentCents - data.priorCents;
  bool get _isUp => _deltaCents > 0;
  bool get _isDown => _deltaCents < 0;
  bool get _isFlat => _deltaCents == 0;

  Color _deltaColor() {
    if (_isFlat) return const Color(0xFF94A3B8);
    final favorable =
        (_isDown && deltaPolarity == EdenFuelPriceDeltaPolarity.lowerIsBetter) ||
            (_isUp && deltaPolarity == EdenFuelPriceDeltaPolarity.higherIsBetter);
    return favorable ? EdenColors.success : EdenColors.error;
  }

  IconData _deltaIcon() {
    if (_isFlat) return Icons.trending_flat;
    return _isUp ? Icons.arrow_upward : Icons.arrow_downward;
  }

  String _deltaLabel() {
    if (_isFlat) return 'No change';
    final sign = _isUp ? '+' : '−'; // unicode minus U+2212
    final abs = _deltaCents.abs();
    final dollars = abs ~/ 100;
    final centsRemainder = abs % 100;
    return '$sign\$$dollars.${centsRemainder.toString().padLeft(2, '0')}';
  }

  /// Hand-rolled relative-time formatter (no `intl` dep). Visible for
  /// testing via direct invocation.
  @visibleForTesting
  static String formatRelative(DateTime asOf, DateTime now) {
    final delta = now.difference(asOf);
    if (delta.inSeconds < 5) return 'Updated just now';
    if (delta.inSeconds < 60) return 'Updated ${delta.inSeconds}s ago';
    if (delta.inMinutes < 60) return 'Updated ${delta.inMinutes}m ago';
    if (delta.inHours < 24) return 'Updated ${delta.inHours}h ago';
    return 'Updated ${delta.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveNow = now ?? DateTime.now();

    final priceWidget = EdenCurrencyDisplay(
      cents: data.currentCents,
      currencyCode: data.currencyCode,
      style: theme.textTheme.headlineSmall,
    );

    final deltaChip = Container(
      key: const ValueKey('eden-fuel-price-delta-chip'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _deltaColor(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_deltaIcon(), size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            _deltaLabel(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    final fuelTypeText = Text(
      data.fuelTypeLabel,
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    final timeText = Text(
      formatRelative(data.asOf, effectiveNow),
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 280;
        if (isWide) {
          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [fuelTypeText, timeText],
                ),
              ),
              const SizedBox(width: 12),
              priceWidget,
              const SizedBox(width: 8),
              deltaChip,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            fuelTypeText,
            const SizedBox(height: 4),
            priceWidget,
            const SizedBox(height: 4),
            deltaChip,
            const SizedBox(height: 4),
            timeText,
          ],
        );
      },
    );
  }
}
