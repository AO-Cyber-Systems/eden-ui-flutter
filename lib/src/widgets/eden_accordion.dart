import 'package:flutter/material.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// A single accordion panel definition.
class EdenAccordionItem {
  const EdenAccordionItem({
    required this.title,
    required this.content,
    this.icon,
  });

  final String title;
  final Widget content;
  final IconData? icon;
}

/// Mirrors the eden_accordion / eden_accordion_item Rails components.
///
/// A vertically stacked set of expandable panels.
class EdenAccordion extends StatefulWidget {
  const EdenAccordion({
    super.key,
    required this.items,
    this.allowMultiple = false,
  });

  final List<EdenAccordionItem> items;
  final bool allowMultiple;

  @override
  State<EdenAccordion> createState() => _EdenAccordionState();
}

class _EdenAccordionState extends State<EdenAccordion> {
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

    return Container(
      decoration: BoxDecoration(
        borderRadius: EdenRadii.borderRadiusLg,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < widget.items.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: theme.colorScheme.outlineVariant),
            _AccordionPanel(
              item: widget.items[i],
              isExpanded: _expandedIndices.contains(i),
              onTap: () => _toggle(i),
            ),
          ],
        ],
      ),
    );
  }
}

class _AccordionPanel extends StatelessWidget {
  const _AccordionPanel({
    required this.item,
    required this.isExpanded,
    required this.onTap,
  });

  final EdenAccordionItem item;
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
              vertical: EdenSpacing.space3,
            ),
            child: Row(
              children: [
                if (item.icon != null) ...[
                  Icon(item.icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(item.title, style: theme.textTheme.titleSmall),
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
            child: item.content,
          ),
          crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}
