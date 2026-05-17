import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'eden_activity_feed_item.dart';
import 'eden_alert.dart';
import 'eden_membership_tier_badge.dart';

// ─────────────────────────────────────────────────────────────────────────
// Value classes
// ─────────────────────────────────────────────────────────────────────────

/// A single recent purchase shown in [EdenLoyaltyMemberDetail]'s recent-
/// purchases list. Consumers must provide entries in reverse-chronological
/// order (most recent first); the widget does not re-sort.
@immutable
class EdenLoyaltyPurchase {
  const EdenLoyaltyPurchase({
    required this.id,
    required this.occurredAt,
    required this.totalCents,
    required this.lineCount,
    this.locationName,
  });

  final String id;
  final DateTime occurredAt;
  final int totalCents;
  final int lineCount;
  final String? locationName;
}

/// Loyalty-program member surfaced by [EdenLoyaltyMemberDetail].
///
/// Generic — knows nothing about retail. Consumer maps domain (loyalty profile
/// + transactions + purchase history) to this shape. Cross-vertical reuse:
/// salon membership, fuel fleet account, medical patient summary, trades
/// customer-of-record.
@immutable
class EdenLoyaltyMember {
  const EdenLoyaltyMember({
    required this.id,
    required this.name,
    this.tier,
    this.customTierLabel,
    this.customTierBackground,
    this.customTierForeground,
    this.points,
    this.lifetimeSpendCents,
    this.birthday,
    this.recentPurchases = const [],
    this.joinedAt,
    this.avatarUrl,
  });

  final String id;
  final String name;

  /// Preset loyalty tier; mutually exclusive with [customTierLabel].
  final EdenMembershipTier? tier;

  /// Custom (non-preset) tier label; takes effect only when [tier] is null.
  final String? customTierLabel;
  final Color? customTierBackground;
  final Color? customTierForeground;

  final int? points;
  final int? lifetimeSpendCents;
  final DateTime? birthday;

  /// Recent purchases in reverse-chronological order (most recent first).
  final List<EdenLoyaltyPurchase> recentPurchases;

  final DateTime? joinedAt;
  final String? avatarUrl;
}

// ─────────────────────────────────────────────────────────────────────────
// Top-level helpers (library-private — names prefixed `edenLoyalty*` so they
// are import-visible to paired tests but not part of the public API surface).
// ─────────────────────────────────────────────────────────────────────────

const List<String> edenLoyaltyMonthsShort = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Returns 1-2 character uppercase initials from a whitespace-separated name.
/// 'Jane Doe' → 'JD'. 'Cher' → 'C'. '  ' → ''.
String edenLoyaltyInitialsFor(String name) {
  final tokens = name
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .toList();
  if (tokens.isEmpty) return '';
  if (tokens.length == 1) {
    return tokens.first.substring(0, 1).toUpperCase();
  }
  return (tokens.first.substring(0, 1) + tokens.last.substring(0, 1))
      .toUpperCase();
}

/// Hand-rolled relative-time formatting (no `intl`). Thresholds:
/// - `<60s` → 'just now'
/// - `<60m` → '{N}m ago'
/// - `<24h` → '{N}h ago'
/// - `<48h` → 'yesterday'
/// - `<14d` → '{N}d ago'
/// - `<60d` → '{N}w ago'
/// - `<365d` → '{Mon} {d}'
/// - else → '{Mon} {d}, {yyyy}'
String edenLoyaltyFormatRelativeTime(DateTime then, DateTime now) {
  final diff = now.difference(then);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inHours < 48) return 'yesterday';
  if (diff.inDays < 14) return '${diff.inDays}d ago';
  if (diff.inDays < 60) return '${(diff.inDays / 7).floor()}w ago';
  if (diff.inDays < 365) {
    return '${edenLoyaltyMonthsShort[then.month - 1]} ${then.day}';
  }
  return '${edenLoyaltyMonthsShort[then.month - 1]} ${then.day}, ${then.year}';
}

/// Format integer cents as USD '\$N.NN'. Hand-rolled; no `intl`.
String edenLoyaltyFormatMoney(int cents) {
  final negative = cents < 0;
  final abs = cents.abs();
  final dollars = abs ~/ 100;
  final fraction = abs % 100;
  final fractionStr = fraction.toString().padLeft(2, '0');
  return '${negative ? '-' : ''}\$$dollars.$fractionStr';
}

/// Format a join-date as 'Mon yyyy' (e.g. `'May 2024'`).
String edenLoyaltyFormatJoinMonthYear(DateTime joined) {
  return '${edenLoyaltyMonthsShort[joined.month - 1]} ${joined.year}';
}

/// True when `birthday` (in its month/day, any year) is within ±[daysWindow]
/// of `now`. Handles year-wrap by checking last/this/next-year candidates.
bool edenLoyaltyIsWithinBirthdayWindow(
  DateTime now,
  DateTime birthday, {
  int daysWindow = 14,
}) {
  final candidates = <DateTime>[
    DateTime(now.year - 1, birthday.month, birthday.day),
    DateTime(now.year, birthday.month, birthday.day),
    DateTime(now.year + 1, birthday.month, birthday.day),
  ];
  for (final c in candidates) {
    if (now.difference(c).inDays.abs() <= daysWindow) return true;
  }
  return false;
}

/// Whole days since the first (most recent) purchase; `-1` when none.
int edenLoyaltyDaysSinceLastVisit(
  List<EdenLoyaltyPurchase> recent,
  DateTime now,
) {
  if (recent.isEmpty) return -1;
  return now.difference(recent.first.occurredAt).inDays;
}

// ─────────────────────────────────────────────────────────────────────────
// Widget
// ─────────────────────────────────────────────────────────────────────────

/// Customer loyalty-profile detail card.
///
/// Top → bottom:
///   1. Header: avatar (image or initials) + name + tier badge
///   2. 3-KPI strip: lifetime spend / points / days since last visit
///   3. Birthday-promo callout (when within ±14 days of [member.birthday])
///   4. Recent purchases (last [maxRecent] via [EdenActivityFeedItem])
///   5. 'Member since {Mon yyyy}' footer
///
/// Generic — no retail-specific binding. See [EdenLoyaltyMember] for the value
/// class. Cross-vertical: salon, fuel, medical, trades all share this shape.
class EdenLoyaltyMemberDetail extends StatelessWidget {
  const EdenLoyaltyMemberDetail({
    super.key,
    required this.member,
    this.maxRecent = 5,
    this.birthdayPromoEnabled = true,
    this.now,
  });

  final EdenLoyaltyMember member;

  /// Max number of [EdenLoyaltyPurchase] rows surfaced. Default 5.
  final int maxRecent;

  /// Toggle for the birthday-promo callout. Default true.
  final bool birthdayPromoEnabled;

  /// Injectable clock for deterministic tests. Defaults to `DateTime.now()`.
  final DateTime? now;

  DateTime _now() => now ?? DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(context),
        const SizedBox(height: EdenSpacing.space4),
        _buildKpiStrip(context),
        _buildBirthdayCallout(context),
        const SizedBox(height: EdenSpacing.space4),
        _buildRecentPurchases(context),
        _buildFooter(context),
      ],
    );
  }

  // ───── Header ─────
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final tierBadge = _resolveTierBadge();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage:
              member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
          child: member.avatarUrl == null
              ? Text(
                  edenLoyaltyInitialsFor(member.name),
                  style: theme.textTheme.titleMedium,
                )
              : null,
        ),
        const SizedBox(width: EdenSpacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(member.name, style: theme.textTheme.titleLarge),
              if (tierBadge != null) ...[
                const SizedBox(height: 4),
                tierBadge,
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget? _resolveTierBadge() {
    if (member.tier != null) {
      return EdenMembershipTierBadge(tier: member.tier!);
    }
    if (member.customTierLabel != null) {
      return EdenMembershipTierBadge.custom(
        label: member.customTierLabel!,
        backgroundColor:
            member.customTierBackground ?? const Color(0xFFE4E4E7),
        foregroundColor:
            member.customTierForeground ?? const Color(0xFF1F2937),
      );
    }
    return null;
  }

  // ───── KPI strip ─────
  Widget _buildKpiStrip(BuildContext context) {
    final spendVal = member.lifetimeSpendCents != null
        ? edenLoyaltyFormatMoney(member.lifetimeSpendCents!)
        : '—';
    final pointsVal = member.points?.toString() ?? '—';
    final days =
        edenLoyaltyDaysSinceLastVisit(member.recentPurchases, _now());
    final daysVal = days >= 0 ? '${days}d' : '—';

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 500;
        final tiles = <Widget>[
          _kpiTile(context, label: 'Lifetime spend', value: spendVal),
          _kpiTile(context, label: 'Points', value: pointsVal),
          _kpiTile(context, label: 'Days since visit', value: daysVal),
        ];
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final t in tiles)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: t,
                ),
            ],
          );
        }
        return Row(
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              Expanded(child: tiles[i]),
              if (i < tiles.length - 1)
                const SizedBox(width: EdenSpacing.space3),
            ],
          ],
        );
      },
    );
  }

  Widget _kpiTile(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(EdenSpacing.space3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  // ───── Birthday callout ─────
  Widget _buildBirthdayCallout(BuildContext context) {
    if (!birthdayPromoEnabled || member.birthday == null) {
      return const SizedBox.shrink();
    }
    if (!edenLoyaltyIsWithinBirthdayWindow(_now(), member.birthday!)) {
      return const SizedBox.shrink();
    }
    final b = member.birthday!;
    return Padding(
      padding: const EdgeInsets.only(top: EdenSpacing.space3),
      child: EdenAlert(
        message:
            'Birthday on ${edenLoyaltyMonthsShort[b.month - 1]} ${b.day} — eligible for birthday promo',
      ),
    );
  }

  // ───── Recent purchases ─────
  Widget _buildRecentPurchases(BuildContext context) {
    final theme = Theme.of(context);
    if (member.recentPurchases.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent purchases', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No recent purchases'),
          ),
        ],
      );
    }
    final initials = edenLoyaltyInitialsFor(member.name);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent purchases', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final p in member.recentPurchases.take(maxRecent))
          EdenActivityFeedItem(
            item: EdenActivityFeedItemData(
              actorName: member.name,
              actorInitials: initials,
              action: 'purchased',
              entityName: _purchaseSummary(p),
              timeAgo: edenLoyaltyFormatRelativeTime(p.occurredAt, _now()),
            ),
          ),
      ],
    );
  }

  String _purchaseSummary(EdenLoyaltyPurchase p) {
    final base =
        '${p.lineCount} items — ${edenLoyaltyFormatMoney(p.totalCents)}';
    return p.locationName != null ? '$base @ ${p.locationName}' : base;
  }

  // ───── Footer ─────
  Widget _buildFooter(BuildContext context) {
    if (member.joinedAt == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: EdenSpacing.space4),
      child: Text(
        'Member since ${edenLoyaltyFormatJoinMonthYear(member.joinedAt!)}',
        style: theme.textTheme.bodySmall,
      ),
    );
  }
}
