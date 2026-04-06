import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// A single reaction with emoji, count, and selection state.
class EdenReaction {
  const EdenReaction({
    required this.emoji,
    required this.count,
    this.isSelected = false,
  });

  final String emoji;
  final int count;
  final bool isSelected;
}

/// A horizontal bar of emoji reaction chips with toggle and add support.
class EdenReactionBar extends StatelessWidget {
  const EdenReactionBar({
    super.key,
    required this.reactions,
    this.onToggleReaction,
    this.onAddReaction,
  });

  final List<EdenReaction> reactions;
  final ValueChanged<String>? onToggleReaction;
  final VoidCallback? onAddReaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Wrap(
      spacing: EdenSpacing.space1,
      runSpacing: EdenSpacing.space1,
      children: [
        for (final reaction in reactions)
          _ReactionChip(
            reaction: reaction,
            isDark: isDark,
            primaryColor: theme.colorScheme.primary,
            onSurface: theme.colorScheme.onSurface,
            onTap: onToggleReaction != null
                ? () => onToggleReaction!(reaction.emoji)
                : null,
          ),
        if (onAddReaction != null)
          Semantics(
            label: 'Add reaction',
            button: true,
            child: GestureDetector(
              onTap: onAddReaction,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? EdenColors.neutral[800]!.withValues(alpha: 0.6)
                      : EdenColors.neutral[100],
                  borderRadius: EdenRadii.borderRadiusFull,
                  border: Border.all(
                    color: isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!,
                  ),
                ),
                child: Icon(
                  Icons.add,
                  size: 14,
                  color: isDark ? EdenColors.neutral[400] : EdenColors.neutral[500],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({
    required this.reaction,
    required this.isDark,
    required this.primaryColor,
    required this.onSurface,
    this.onTap,
  });

  final EdenReaction reaction;
  final bool isDark;
  final Color primaryColor;
  final Color onSurface;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${reaction.emoji} reaction, ${reaction.count}',
      button: onTap != null,
      toggled: reaction.isSelected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: reaction.isSelected
                ? primaryColor.withValues(alpha: 0.1)
                : (isDark
                    ? EdenColors.neutral[800]!.withValues(alpha: 0.6)
                    : EdenColors.neutral[100]),
            borderRadius: EdenRadii.borderRadiusFull,
            border: Border.all(
              color: reaction.isSelected
                  ? primaryColor.withValues(alpha: 0.4)
                  : (isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(reaction.emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                '${reaction.count}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: reaction.isSelected
                      ? primaryColor
                      : onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
