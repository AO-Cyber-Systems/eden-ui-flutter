import 'package:flutter/material.dart';

import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Preset membership/loyalty tiers with built-in palette + icon.
enum EdenMembershipTier { bronze, silver, gold, platinum, vip }

/// Internal tier visual descriptor.
class _TierStyle {
  const _TierStyle({
    required this.label,
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData icon;
}

/// Membership-tier Chip-like badge.
///
/// Two construction modes:
///  - `EdenMembershipTierBadge(tier: EdenMembershipTier.gold)` — preset tier
///    with built-in palette + icon.
///  - `EdenMembershipTierBadge.custom(label: ..., backgroundColor: ..., ...)`
///    — caller-supplied palette for verticals that don't fit the preset set
///    (salon/retail/legal/gov clearance, etc).
///
/// Distinct from `EdenBadge` because tier-specific palette + adornment icon
/// are baked in for the preset path.
class EdenMembershipTierBadge extends StatelessWidget {
  /// Preset tier constructor.
  const EdenMembershipTierBadge({
    super.key,
    required EdenMembershipTier this.tier,
    this.showIcon = true,
  })  : _customLabel = null,
        _customBg = null,
        _customFg = null,
        _customIcon = null;

  /// Custom tier constructor — caller-supplied palette.
  const EdenMembershipTierBadge.custom({
    super.key,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
    IconData? icon,
  })  : tier = null,
        showIcon = icon != null,
        _customLabel = label,
        _customBg = backgroundColor,
        _customFg = foregroundColor,
        _customIcon = icon;

  final EdenMembershipTier? tier;
  final bool showIcon;
  final String? _customLabel;
  final Color? _customBg;
  final Color? _customFg;
  final IconData? _customIcon;

  static const Map<EdenMembershipTier, _TierStyle> _presetStyles = {
    EdenMembershipTier.bronze: _TierStyle(
      label: 'Bronze',
      background: Color(0xFFEFE3D3),
      foreground: Color(0xFF7B5E3C),
      icon: Icons.emoji_events,
    ),
    EdenMembershipTier.silver: _TierStyle(
      label: 'Silver',
      background: Color(0xFFE4E4E7),
      foreground: Color(0xFF52525B),
      icon: Icons.emoji_events,
    ),
    EdenMembershipTier.gold: _TierStyle(
      label: 'Gold',
      background: Color(0xFFFAECD5),
      foreground: Color(0xFFA67A38),
      icon: Icons.star,
    ),
    EdenMembershipTier.platinum: _TierStyle(
      label: 'Platinum',
      background: Color(0xFFE0E7EF),
      foreground: Color(0xFF334155),
      icon: Icons.shield,
    ),
    EdenMembershipTier.vip: _TierStyle(
      label: 'VIP',
      background: Color(0xFFFDF8EF),
      foreground: Color(0xFFD4A853),
      icon: Icons.workspace_premium,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color bg;
    final Color fg;
    final IconData? icon;

    if (tier != null) {
      final style = _presetStyles[tier!]!;
      label = style.label;
      bg = style.background;
      fg = style.foreground;
      icon = showIcon ? style.icon : null;
    } else {
      label = _customLabel!;
      bg = _customBg!;
      fg = _customFg!;
      icon = (showIcon && _customIcon != null) ? _customIcon : null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space3,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: EdenRadii.borderRadiusFull,
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

