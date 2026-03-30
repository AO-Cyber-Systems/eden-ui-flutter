import 'package:flutter/material.dart';
import '../tokens/spacing.dart';
import '../tokens/radii.dart';

/// A single FAQ item.
class EdenFAQItem {
  const EdenFAQItem({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;
}

/// A FAQ section with expandable question/answer pairs.
///
/// Uses an accordion pattern for expand/collapse.
class EdenFAQSection extends StatefulWidget {
  const EdenFAQSection({
    super.key,
    this.title,
    this.subtitle,
    required this.items,
    this.padding,
    this.allowMultiple = false,
  });

  /// Optional section title.
  final String? title;

  /// Optional subtitle.
  final String? subtitle;

  /// List of FAQ question/answer pairs.
  final List<EdenFAQItem> items;

  /// Custom padding.
  final EdgeInsets? padding;

  /// Whether multiple items can be expanded at once.
  final bool allowMultiple;

  @override
  State<EdenFAQSection> createState() => _EdenFAQSectionState();
}

class _EdenFAQSectionState extends State<EdenFAQSection> {
  final Set<int> _expandedIndices = {};

  void _toggle(int index) {
    setState(() {
      if (_expandedIndices.contains(index)) {
        _expandedIndices.remove(index);
      } else {
        if (!widget.allowMultiple) _expandedIndices.clear();
        _expandedIndices.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: widget.padding ??
          const EdgeInsets.symmetric(
            horizontal: EdenSpacing.space6,
            vertical: EdenSpacing.space12,
          ),
      child: Column(
        children: [
          if (widget.title != null) ...[
            Text(
              widget.title!,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: EdenSpacing.space2),
              Text(
                widget.subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: EdenSpacing.space8),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: EdenRadii.borderRadiusLg,
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (int i = 0; i < widget.items.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: theme.colorScheme.outlineVariant,
                      ),
                    _FAQPanel(
                      item: widget.items[i],
                      isExpanded: _expandedIndices.contains(i),
                      onTap: () => _toggle(i),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FAQPanel extends StatelessWidget {
  const _FAQPanel({
    required this.item,
    required this.isExpanded,
    required this.onTap,
  });

  final EdenFAQItem item;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: EdenSpacing.space4,
              vertical: EdenSpacing.space4,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.question,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(
              EdenSpacing.space4,
              0,
              EdenSpacing.space4,
              EdenSpacing.space4,
            ),
            child: Text(
              item.answer,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
          ),
          crossFadeState:
              isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}
