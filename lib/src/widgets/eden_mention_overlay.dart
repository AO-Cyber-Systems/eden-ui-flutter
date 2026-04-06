import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/shadows.dart';
import '../tokens/spacing.dart';

/// A suggestion for the @-mention autocomplete.
class EdenMentionSuggestion {
  const EdenMentionSuggestion({
    required this.id,
    required this.displayName,
    this.username,
    this.avatarUrl,
  });

  final String id;
  final String displayName;
  final String? username;
  final String? avatarUrl;
}

/// An @-mention autocomplete dropdown overlay.
class EdenMentionOverlay extends StatelessWidget {
  const EdenMentionOverlay({
    super.key,
    required this.suggestions,
    required this.onSelect,
    this.searchText,
    this.maxHeight = 200,
  });

  final List<EdenMentionSuggestion> suggestions;
  final ValueChanged<EdenMentionSuggestion> onSelect;
  final String? searchText;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: isDark ? EdenColors.neutral[800] : Colors.white,
        borderRadius: EdenRadii.borderRadiusLg,
        border: Border.all(
          color: isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!,
        ),
        boxShadow: EdenShadows.lg(dark: isDark),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: EdenSpacing.space1),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return _MentionTile(
            suggestion: suggestion,
            searchText: searchText,
            isDark: isDark,
            primaryColor: theme.colorScheme.primary,
            onSurface: theme.colorScheme.onSurface,
            onTap: () => onSelect(suggestion),
          );
        },
      ),
    );
  }
}

class _MentionTile extends StatelessWidget {
  const _MentionTile({
    required this.suggestion,
    required this.isDark,
    required this.primaryColor,
    required this.onSurface,
    required this.onTap,
    this.searchText,
  });

  final EdenMentionSuggestion suggestion;
  final bool isDark;
  final Color primaryColor;
  final Color onSurface;
  final VoidCallback onTap;
  final String? searchText;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Mention ${suggestion.displayName}',
      button: true,
      child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: EdenSpacing.space3,
          vertical: EdenSpacing.space2,
        ),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: EdenSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHighlightedText(
                    suggestion.displayName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: onSurface,
                    ),
                  ),
                  if (suggestion.username != null)
                    _buildHighlightedText(
                      '@${suggestion.username!}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? EdenColors.neutral[400]
                            : EdenColors.neutral[500],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildAvatar() {
    final initials = suggestion.displayName.isNotEmpty
        ? suggestion.displayName
            .split(' ')
            .take(2)
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
            .join()
        : '?';

    return CircleAvatar(
      radius: 16,
      backgroundColor: primaryColor.withValues(alpha: 0.1),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: primaryColor,
        ),
      ),
    );
  }

  Widget _buildHighlightedText(String text, {required TextStyle style}) {
    if (searchText == null || searchText!.isEmpty) {
      return Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
    }

    final query = searchText!.toLowerCase();
    final lower = text.toLowerCase();
    final matchIndex = lower.indexOf(query);

    if (matchIndex < 0) {
      return Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
    }

    return Text.rich(
      TextSpan(
        children: [
          if (matchIndex > 0)
            TextSpan(text: text.substring(0, matchIndex), style: style),
          TextSpan(
            text: text.substring(matchIndex, matchIndex + searchText!.length),
            style: style.copyWith(fontWeight: FontWeight.w700),
          ),
          if (matchIndex + searchText!.length < text.length)
            TextSpan(
              text: text.substring(matchIndex + searchText!.length),
              style: style,
            ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
