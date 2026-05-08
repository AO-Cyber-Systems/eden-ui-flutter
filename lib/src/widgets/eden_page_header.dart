import 'package:flutter/material.dart';
import '../tokens/spacing.dart';

/// Mirrors the eden_page_header Rails component.
///
/// Page title with optional description and trailing action widgets.
///
/// Responsive behavior: at viewport widths below 480pt with a non-empty
/// `actions` list, the actions block stacks vertically below the title block
/// (using a [Wrap] so long action labels can themselves line-break safely). At
/// 480pt and above, the original side-by-side layout is preserved. When
/// `actions` is null or empty, the side-by-side layout is used at all widths.
class EdenPageHeader extends StatelessWidget {
  const EdenPageHeader({
    super.key,
    required this.title,
    this.description,
    this.actions,
    this.leading,
  });

  final String title;
  final String? description;
  final List<Widget>? actions;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: EdenSpacing.space6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final hasActions = actions != null && actions!.isNotEmpty;
          final stackVertically = hasActions && constraints.maxWidth < 480;

          final titleBlock = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: EdenSpacing.space3),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.headlineMedium),
                    if (description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );

          final actionsBlock = hasActions
              ? Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: actions!,
                )
              : null;

          if (stackVertically) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleBlock,
                const SizedBox(height: EdenSpacing.space3),
                actionsBlock!,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: titleBlock),
              if (actionsBlock != null) ...[
                const SizedBox(width: EdenSpacing.space3),
                actionsBlock,
              ],
            ],
          );
        },
      ),
    );
  }
}
