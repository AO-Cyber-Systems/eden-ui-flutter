import 'package:flutter/material.dart';

/// A tappable card for selecting a starter template in onboarding flows.
///
/// Used by the "Get Started" wizard across every Eden Biz vertical
/// (salon quickstart, HVAC starter, medical practice template, legal-firm
/// starter, etc.). Pattern donor: trades-flutter
/// `lib/features/onboarding/presentation/widgets/starter_template_card.dart`.
///
/// Renders:
/// - thumbnail (Widget — typically Image or Icon)
/// - title
/// - description
/// - optional effort badge (e.g. "~10 min setup")
/// - optional "selected" visual highlight
class EdenStarterTemplateCard extends StatelessWidget {
  /// Creates a starter-template card.
  const EdenStarterTemplateCard({
    super.key,
    required this.title,
    required this.description,
    this.thumbnail,
    this.effortLabel,
    this.selected = false,
    this.onSelect,
  });

  /// Card heading.
  final String title;

  /// Two-line description shown under the title.
  final String description;

  /// Leading thumbnail widget (Image or Icon — caller's choice).
  final Widget? thumbnail;

  /// Optional effort hint, e.g. "~10 min setup".
  final String? effortLabel;

  /// When true, renders a thicker accent border + tinted background.
  final bool selected;

  /// Tap callback. When null, the card is non-interactive.
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final Color borderColor =
        selected ? cs.primary : cs.outlineVariant.withValues(alpha: 0.5);
    final double borderWidth = selected ? 2.0 : 1.0;
    final Color bg =
        selected ? cs.primaryContainer.withValues(alpha: 0.18) : cs.surface;

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (thumbnail != null) ...<Widget>[
            SizedBox(
              key: const ValueKey<String>('thumbnail_slot'),
              child: thumbnail,
            ),
            const SizedBox(height: 12),
          ],
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
              height: 1.3,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (effortLabel != null) ...<Widget>[
            const SizedBox(height: 12),
            Container(
              key: const ValueKey<String>('effort_badge'),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                effortLabel!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (onSelect == null) return card;
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(12),
      child: card,
    );
  }
}
