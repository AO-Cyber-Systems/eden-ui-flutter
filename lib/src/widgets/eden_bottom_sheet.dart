import 'package:flutter/material.dart';

import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// A styled bottom sheet matching Eden UI tokens.
///
/// Use [EdenBottomSheet.show] to display a modal bottom sheet with a drag
/// handle, optional title bar, scrollable content, and an actions row.
class EdenBottomSheet {
  EdenBottomSheet._();

  /// Shows a modal bottom sheet styled with Eden design tokens.
  ///
  /// [initialHeight] is a fraction of screen height (0.0 - 1.0).
  /// [minHeight] and [maxHeight] constrain the drag range as fractions.
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    String? title,
    List<Widget>? actions,
    double initialHeight = 0.5,
    double? minHeight,
    double? maxHeight,
    bool isDismissible = true,
    bool showDragHandle = true,
    bool enableDrag = true,
    bool isScrollControlled = true,
    Color? backgroundColor,
  }) {
    final theme = Theme.of(context);
    final bg = backgroundColor ?? theme.colorScheme.surface;

    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      constraints: maxHeight != null
          ? BoxConstraints(
              maxHeight:
                  MediaQuery.of(context).size.height * maxHeight.clamp(0, 1),
            )
          : null,
      builder: (context) {
        final screenH = MediaQuery.of(context).size.height;
        final effectiveMin = minHeight ?? 0.25;
        final effectiveMax = maxHeight ?? 1.0;
        final clampedInitial =
            initialHeight.clamp(effectiveMin, effectiveMax);

        return _EdenBottomSheetContent(
          title: title,
          actions: actions,
          showDragHandle: showDragHandle,
          backgroundColor: bg,
          initialFraction: clampedInitial,
          screenHeight: screenH,
          child: child,
        );
      },
    );
  }
}

class _EdenBottomSheetContent extends StatelessWidget {
  const _EdenBottomSheetContent({
    required this.child,
    required this.backgroundColor,
    required this.initialFraction,
    required this.screenHeight,
    this.title,
    this.actions,
    this.showDragHandle = true,
  });

  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final bool showDragHandle;
  final Color backgroundColor;
  final double initialFraction;
  final double screenHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasActions = actions != null && actions!.isNotEmpty;

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * initialFraction,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(EdenRadii.xl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          if (showDragHandle)
            Padding(
              padding: const EdgeInsets.only(top: EdenSpacing.space2),
              child: Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: EdenRadii.borderRadiusFull,
                  ),
                ),
              ),
            ),

          // Title bar
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                EdenSpacing.space6,
                EdenSpacing.space4,
                EdenSpacing.space4,
                EdenSpacing.space2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Semantics(
                    label: 'Close',
                    button: true,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Divider below title
          if (title != null)
            Divider(
              height: 1,
              color: theme.colorScheme.outlineVariant,
            ),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(EdenSpacing.space6),
              child: child,
            ),
          ),

          // Actions row
          if (hasActions) ...[
            Divider(
              height: 1,
              color: theme.colorScheme.outlineVariant,
            ),
            Padding(
              padding: const EdgeInsets.all(EdenSpacing.space4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (int i = 0; i < actions!.length; i++) ...[
                    if (i > 0)
                      const SizedBox(width: EdenSpacing.space2),
                    actions![i],
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
