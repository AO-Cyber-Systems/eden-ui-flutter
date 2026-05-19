import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'eden_app_mode.dart' show kEdenAppModeCompactMax;
import 'eden_authenticated_image.dart';
import 'eden_card.dart';
import 'eden_currency_display.dart';
import 'eden_empty_state.dart';
import 'eden_stock_level_indicator.dart';

/// A single product cell rendered by [EdenQuickAddProductGrid].
///
/// Generic value class — no retail-domain binding. Consumer maps any domain
/// (parts catalog / services menu / inventory SKUs / fuel pricing slots /
/// gov vending) into a [List<EdenQuickAddProduct>].
@immutable
class EdenQuickAddProduct {
  const EdenQuickAddProduct({
    required this.id,
    required this.name,
    required this.priceCents,
    this.currency = 'USD',
    this.photoUrl,
    this.onHand,
    this.reorderPoint,
    this.categoryId,
    this.sku,
  });

  final String id;
  final String name;
  final int priceCents;
  final String currency;

  /// Optional signed image URL passed to [EdenAuthenticatedImage]. When `null`
  /// the tile renders a placeholder icon instead.
  final String? photoUrl;

  /// Optional on-hand count. When non-null, the tile renders an
  /// [EdenStockLevelIndicator] corner overlay.
  final int? onHand;

  /// Optional reorder threshold. Drives the stock-indicator color thresholds
  /// (see [EdenStockLevelIndicator]). When null or zero the indicator falls
  /// back to a binary in-stock / out-of-stock signal.
  final int? reorderPoint;

  /// Optional category id — paired with [EdenQuickAddProductGrid.categories]
  /// for the chip-strip filter. The grid itself does NOT filter; the consumer
  /// passes a pre-filtered list.
  final String? categoryId;

  final String? sku;
}

/// Filter chip entry for [EdenQuickAddProductGrid.categories].
@immutable
class EdenQuickAddCategory {
  const EdenQuickAddCategory({
    required this.id,
    required this.label,
    this.icon,
  });

  final String id;
  final String label;
  final IconData? icon;
}

/// Touch-friendly product tile grid for retail POS quick-add, trades quick
/// quote parts picker, fuel parts grid, salon retail front-counter, gov
/// vending. Generic — see [EdenQuickAddProduct] for the value-class contract.
///
/// Composes existing primitives:
/// - [EdenAuthenticatedImage] for the product photo (`photoUrl`) with a
///   placeholder icon fallback when null.
/// - [EdenStockLevelIndicator] as a corner overlay when `onHand != null`.
/// - [EdenCurrencyDisplay] for the price.
/// - [EdenCard] as the tile wrapper.
/// - [EdenEmptyState] when the products list is empty.
///
/// Tap-to-add: tile tap fires [onTap] with the tapped product. Drag-to-cart:
/// every tile is wrapped in a [LongPressDraggable] of `EdenQuickAddProduct`;
/// the consumer wires a [DragTarget] on the cart side. This widget is
/// drag-source only — it never contains its own DragTarget.
///
/// Responsive — [crossAxisCount] auto-derives from [LayoutBuilder] constraints
/// (NOT [MediaQuery] which would break in constrained subtrees like the POS
/// register's left zone):
/// - `< 600pt` → 4 cols (mobile / iPhone-narrow)
/// - `600..1024pt` → 6 cols (iPad portrait / small tablet)
/// - `>= 1024pt` → 8 cols (iPad landscape / desktop)
///
/// Explicit `crossAxisCount: int?` always wins.
///
/// Optional category chip strip via [categories] + [selectedCategoryId] +
/// [onCategorySelected]. The grid does NOT filter — the consumer passes a
/// pre-filtered `products` list. The chip strip is purely a UI affordance
/// fired upward.
class EdenQuickAddProductGrid extends StatelessWidget {
  const EdenQuickAddProductGrid({
    super.key,
    required this.products,
    this.onTap,
    this.crossAxisCount,
    this.categories,
    this.selectedCategoryId,
    this.onCategorySelected,
    this.emptyLabel = 'No products',
  });

  final List<EdenQuickAddProduct> products;
  final ValueChanged<EdenQuickAddProduct>? onTap;

  /// Explicit override; when null, auto-derives from [LayoutBuilder]
  /// constraints (4 / 6 / 8 cols).
  final int? crossAxisCount;

  final List<EdenQuickAddCategory>? categories;
  final String? selectedCategoryId;
  final ValueChanged<String?>? onCategorySelected;
  final String emptyLabel;

  int _autoCols(double width) {
    if (width < kEdenAppModeCompactMax) return 4;
    if (width < 1024) {
      // breakpoint: 1024 — product-grid medium-tier column count
      return 6;
    }
    return 8;
  }

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return EdenEmptyState(title: emptyLabel);
    }
    final body = LayoutBuilder(
      builder: (context, constraints) {
        final cols = crossAxisCount ?? _autoCols(constraints.maxWidth);
        final tileWidth = constraints.maxWidth / cols;
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            // Tile-height = tileWidth / aspectRatio. With aspectRatio 0.6
            // and a 96pt tile, tile-height ≈ 160pt — enough for a square
            // photo (~96pt) + 4pt gap + 2-line name (≈32pt) + 2pt gap +
            // currency-display label (≈18pt) + 8pt outer padding without
            // overflow.
            childAspectRatio: 0.6,
            crossAxisSpacing: EdenSpacing.space2,
            mainAxisSpacing: EdenSpacing.space2,
          ),
          itemCount: products.length,
          itemBuilder: (ctx, i) {
            final p = products[i];
            final tile = _ProductTile(product: p, onTap: onTap);
            return LongPressDraggable<EdenQuickAddProduct>(
              data: p,
              delay: const Duration(milliseconds: 200),
              feedback: Material(
                elevation: 8,
                color: Colors.transparent,
                child: SizedBox(
                  width: tileWidth,
                  child: _ProductTile(product: p, onTap: null),
                ),
              ),
              childWhenDragging: Opacity(opacity: 0.4, child: tile),
              child: tile,
            );
          },
        );
      },
    );
    if (categories == null || categories!.isEmpty) {
      return body;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: EdenSpacing.space2,
            vertical: EdenSpacing.space2,
          ),
          child: Wrap(
            spacing: EdenSpacing.space2,
            runSpacing: EdenSpacing.space1,
            children: [
              for (final c in categories!)
                ChoiceChip(
                  label: Text(c.label),
                  avatar: c.icon == null ? null : Icon(c.icon, size: 18),
                  selected: selectedCategoryId == c.id,
                  onSelected: onCategorySelected == null
                      ? null
                      : (sel) => onCategorySelected!(sel ? c.id : null),
                ),
            ],
          ),
        ),
        Expanded(child: body),
      ],
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.onTap});

  final EdenQuickAddProduct product;
  final ValueChanged<EdenQuickAddProduct>? onTap;

  /// `onHand / (reorderPoint * 2)` so the reorder point sits at the amber
  /// 50% threshold. Falls back to a binary in-stock / out-of-stock signal
  /// when `reorderPoint` is null or zero.
  ///
  /// Returns `null` when [EdenQuickAddProduct.onHand] is null — the tile
  /// suppresses the stock-indicator overlay entirely in that case.
  ({int currentStock, int reorderPoint})? _stockArgs() {
    final h = product.onHand;
    if (h == null) return null;
    final rp = product.reorderPoint;
    if (rp == null || rp <= 0) {
      // Binary mode: reorderPoint=0 + currentStock=0 → red.
      return (currentStock: h, reorderPoint: 0);
    }
    return (currentStock: h, reorderPoint: rp);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stock = _stockArgs();
    return EdenCard(
      padding: EdgeInsets.zero,
      onTap: onTap == null ? null : () => onTap!(product),
      child: Padding(
        padding: const EdgeInsets.all(EdenSpacing.space1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Photo zone takes remaining vertical space inside the tile so
            // the bottom name+price block always fits. The tile's aspect
            // ratio guarantees the column has more height than the text
            // block plus padding.
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: product.photoUrl != null
                        ? EdenAuthenticatedImage(
                            url: product.photoUrl!,
                            fit: BoxFit.cover,
                          )
                        : const _PlaceholderTileIcon(),
                  ),
                  if (stock != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      left: 4,
                      child: EdenStockLevelIndicator(
                        currentStock: stock.currentStock,
                        reorderPoint: stock.reorderPoint,
                        showLabel: false,
                        height: 6,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: EdenSpacing.space1),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: 2),
            EdenCurrencyDisplay(
              cents: product.priceCents,
              currencyCode: product.currency,
              style: theme.textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderTileIcon extends StatelessWidget {
  const _PlaceholderTileIcon();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 32,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}
