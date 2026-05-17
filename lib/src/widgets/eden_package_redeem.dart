import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'eden_button.dart';
import 'eden_card.dart';
import 'eden_service_catalog_tile.dart';

/// Multi-visit package — customer pre-purchases a bundle of service visits,
/// then redeems them at checkout. Generic across verticals.
@immutable
class EdenPackage {
  const EdenPackage({
    required this.id,
    required this.customerId,
    required this.name,
    required this.totalVisits,
    required this.remainingVisits,
    required this.purchasedAt,
    this.expiresAt,
    this.transferable = false,
    this.applicableServices = const [],
  });

  final String id;
  final String customerId;
  final String name;
  final int totalVisits;
  final int remainingVisits;
  final DateTime purchasedAt;
  final DateTime? expiresAt;
  final bool transferable;
  final List<String> applicableServices;
}

/// Package balance + apply-to-line-item picker — filters packages by
/// applicableServices when [serviceEntry] is provided. Emits
/// `onRedeem(packageId, visitsToApply)` for the consumer to wire backend RPC.
class EdenPackageRedeem extends StatelessWidget {
  const EdenPackageRedeem({
    super.key,
    required this.packages,
    required this.onRedeem,
    this.serviceEntry,
    this.maxApplyButtonsPerPackage = 3,
    this.nowOverride,
  });

  final List<EdenPackage> packages;
  final void Function(String packageId, int visitsToApply) onRedeem;
  final EdenServiceCatalogEntry? serviceEntry;
  final int maxApplyButtonsPerPackage;
  final DateTime? nowOverride;

  DateTime get _now => nowOverride ?? DateTime.now();

  List<EdenPackage> get _applicable {
    return packages.where((p) {
      if (p.remainingVisits <= 0) return false;
      if (p.expiresAt != null && p.expiresAt!.isBefore(_now)) return false;
      if (serviceEntry != null &&
          !p.applicableServices.contains(serviceEntry!.id)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final list = _applicable;
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(EdenSpacing.space4),
          child: Text(
            serviceEntry == null
                ? 'No packages available'
                : 'No applicable packages for "${serviceEntry!.name}"',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      itemCount: list.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: EdenSpacing.space2),
      itemBuilder: (ctx, i) => _PackageCard(
        package: list[i],
        maxButtons: maxApplyButtonsPerPackage,
        onRedeem: onRedeem,
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.package,
    required this.maxButtons,
    required this.onRedeem,
  });

  final EdenPackage package;
  final int maxButtons;
  final void Function(String packageId, int visitsToApply) onRedeem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonCount = package.remainingVisits.clamp(0, maxButtons);
    return EdenCard(
      child: Padding(
        padding: const EdgeInsets.all(EdenSpacing.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.inventory_2_outlined),
                const SizedBox(width: EdenSpacing.space2),
                Expanded(
                  child: Text(
                    package.name,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${package.remainingVisits} of ${package.totalVisits}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Purchased ${_formatShortDate(package.purchasedAt)}'
              '${package.expiresAt != null ? ' · Expires ${_formatShortDate(package.expiresAt!)}' : ''}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: EdenSpacing.space2),
            Wrap(
              spacing: EdenSpacing.space2,
              runSpacing: EdenSpacing.space2,
              children: [
                for (var v = 1; v <= buttonCount; v++)
                  EdenButton(
                    label: 'Apply $v visit${v == 1 ? '' : 's'}',
                    size: EdenButtonSize.sm,
                    onPressed: () => onRedeem(package.id, v),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatShortDate(DateTime d) => '${d.month}/${d.day}/${d.year}';
}
