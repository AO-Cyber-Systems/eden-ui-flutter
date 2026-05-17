import 'package:flutter/material.dart';

import '../theme/eden_theme_profile.dart';
import '../theme/eden_theme_profile_scope.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import 'eden_avatar.dart';
import 'eden_card.dart';
import 'eden_chip.dart';
import 'eden_currency_display.dart';

/// Staff member capable of performing a catalog service.
///
/// Generic across verticals — salon stylist, trades technician, medical
/// provider, fuel delivery driver. Consumer maps domain types here.
@immutable
class EdenServiceStaff {
  const EdenServiceStaff({
    required this.id,
    required this.displayName,
    required this.initials,
    this.avatarUrl,
  });

  final String id;
  final String displayName;
  final String initials;
  final String? avatarUrl;
}

/// Per-entry customization (optional add-on / variant).
@immutable
class EdenServiceCustomization {
  const EdenServiceCustomization({
    required this.id,
    required this.label,
    this.priceCentsDelta,
    this.durationMinutesDelta,
  });

  final String id;
  final String label;
  final int? priceCentsDelta;
  final int? durationMinutesDelta;
}

/// Deposit-policy descriptor for a service. Either flat-amount or percentage —
/// consumer enforces mutual exclusion.
@immutable
class EdenServiceDepositPolicy {
  const EdenServiceDepositPolicy({this.amountCents, this.percentage});

  final int? amountCents;
  final int? percentage;
}

/// Catalog entry rendered by [EdenServiceCatalogTile].
///
/// Generic — works for salon services, trades labor catalog, medical procedure
/// catalog, fuel delivery service catalog. No salon-specific fields.
@immutable
class EdenServiceCatalogEntry {
  const EdenServiceCatalogEntry({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.priceCents,
    this.currency = 'USD',
    this.capableStaff = const [],
    this.customizations = const [],
    this.photoUrl,
    this.categoryId,
    this.onlineBookable = true,
    this.depositPolicy,
    this.description,
  });

  final String id;
  final String name;
  final int durationMinutes;
  final int priceCents;
  final String currency;
  final List<EdenServiceStaff> capableStaff;
  final List<EdenServiceCustomization> customizations;
  final String? photoUrl;
  final String? categoryId;
  final bool onlineBookable;
  final EdenServiceDepositPolicy? depositPolicy;
  final String? description;
}

/// Pure helper — formats a duration in minutes as '30m' / '1h' / '1h 30m'.
/// Public for direct unit testing.
@visibleForTesting
String formatServiceDuration(int minutes) {
  if (minutes < 60) return '${minutes}m';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}

/// Salon-backbone service tile — name + duration + price + capable-staff avatar
/// strip + customizations chip strip. Tap-to-book fires `onTap(entry)`.
///
/// Composes obj 001 primitives: [EdenCard], [EdenAvatar], [EdenCurrencyDisplay],
/// [EdenChip]. Theme-profile aware via [EdenThemeProfileScope] (falls back to
/// commercialWarm when scope is absent).
class EdenServiceCatalogTile extends StatelessWidget {
  const EdenServiceCatalogTile({
    super.key,
    required this.entry,
    this.onTap,
    this.customizationsBuilder,
    this.trailing,
    this.maxVisibleAvatars = 5,
  });

  final EdenServiceCatalogEntry entry;
  final ValueChanged<EdenServiceCatalogEntry>? onTap;

  /// Optional builder slot — when non-null, replaces the default customizations
  /// chip strip. Invoked even when [entry.customizations] is empty (consumer can
  /// render their own empty-state).
  final Widget Function(BuildContext, EdenServiceCatalogEntry)?
      customizationsBuilder;

  /// Optional trailing slot — verticals surface extra metadata here (e.g. salon
  /// photo thumbnail / trades vehicle-required icon).
  final Widget? trailing;

  final int maxVisibleAvatars;

  @override
  Widget build(BuildContext context) {
    // Theme-profile fallback — explicit read primes future palette swaps when
    // a salonVibrant profile is later added to the enum.
    // ignore: unused_local_variable
    final profile = EdenThemeProfileScope.maybeOf(context) ??
        EdenThemeProfile.commercialWarm;
    final theme = Theme.of(context);

    return EdenCard(
      onTap: onTap == null ? null : () => onTap!(entry),
      child: Padding(
        padding: const EdgeInsets.all(EdenSpacing.space3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Photo(entry: entry),
            const SizedBox(width: EdenSpacing.space3),
            Expanded(
              child: _Body(
                entry: entry,
                theme: theme,
                maxVisibleAvatars: maxVisibleAvatars,
                customizationsBuilder: customizationsBuilder,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: EdenSpacing.space2),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.entry});

  final EdenServiceCatalogEntry entry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(EdenRadii.md),
      child: SizedBox(
        width: 56,
        height: 56,
        child: entry.photoUrl != null
            ? Image.network(
                entry.photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _PlaceholderIcon(cs: cs),
              )
            : _PlaceholderIcon(cs: cs),
      ),
    );
  }
}

class _PlaceholderIcon extends StatelessWidget {
  const _PlaceholderIcon({required this.cs});

  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: cs.surfaceContainerHighest,
      child: Icon(Icons.spa_outlined, color: cs.onSurfaceVariant, size: 28),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.entry,
    required this.theme,
    required this.maxVisibleAvatars,
    this.customizationsBuilder,
  });

  final EdenServiceCatalogEntry entry;
  final ThemeData theme;
  final int maxVisibleAvatars;
  final Widget Function(BuildContext, EdenServiceCatalogEntry)?
      customizationsBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          entry.name,
          style: theme.textTheme.titleSmall,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatServiceDuration(entry.durationMinutes),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(width: EdenSpacing.space2),
            Text('·', style: theme.textTheme.bodyMedium),
            const SizedBox(width: EdenSpacing.space2),
            EdenCurrencyDisplay(
              cents: entry.priceCents,
              currencyCode: entry.currency,
            ),
          ],
        ),
        if (entry.capableStaff.isNotEmpty) ...[
          const SizedBox(height: EdenSpacing.space2),
          _AvatarStrip(
              staff: entry.capableStaff, maxVisible: maxVisibleAvatars),
        ],
        if (entry.customizations.isNotEmpty || customizationsBuilder != null) ...[
          const SizedBox(height: EdenSpacing.space2),
          customizationsBuilder?.call(context, entry) ??
              _CustomizationsStrip(items: entry.customizations),
        ],
      ],
    );
  }
}

class _AvatarStrip extends StatelessWidget {
  const _AvatarStrip({required this.staff, required this.maxVisible});

  final List<EdenServiceStaff> staff;
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    final visible =
        staff.length <= maxVisible ? staff : staff.sublist(0, maxVisible);
    final overflow = staff.length - visible.length;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final s in visible)
          EdenAvatar(
            initials: s.initials,
            image: s.avatarUrl != null ? NetworkImage(s.avatarUrl!) : null,
            size: EdenAvatarSize.sm,
          ),
        if (overflow > 0) EdenChip(label: '+$overflow'),
      ],
    );
  }
}

class _CustomizationsStrip extends StatelessWidget {
  const _CustomizationsStrip({required this.items});

  final List<EdenServiceCustomization> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [for (final c in items) EdenChip(label: c.label)],
    );
  }
}
