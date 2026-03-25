import 'package:flutter/material.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Modal size presets matching the Rails component.
enum EdenModalSize { sm, md, lg, xl }

/// Mirrors the eden_modal Rails component.
///
/// Use [EdenModal.show] to display a modal dialog.
class EdenModal {
  EdenModal._();

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    String? title,
    EdenModalSize size = EdenModalSize.md,
    bool dismissible = true,
    List<Widget>? actions,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: dismissible,
      builder: (context) => _EdenModalContent(
        title: title,
        size: size,
        actions: actions,
        child: child,
      ),
    );
  }
}

class _EdenModalContent extends StatelessWidget {
  const _EdenModalContent({
    required this.child,
    this.title,
    required this.size,
    this.actions,
  });

  final Widget child;
  final String? title;
  final EdenModalSize size;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxWidth = _resolveWidth();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: EdenRadii.borderRadiusXl),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.all(EdenSpacing.space6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null)
                Row(
                  children: [
                    Expanded(
                      child: Text(title!, style: theme.textTheme.titleLarge),
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
              if (title != null) const SizedBox(height: EdenSpacing.space4),
              child,
              if (actions != null && actions!.isNotEmpty) ...[
                const SizedBox(height: EdenSpacing.space6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (int i = 0; i < actions!.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      actions![i],
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  double _resolveWidth() {
    switch (size) {
      case EdenModalSize.sm:
        return 360;
      case EdenModalSize.md:
        return 480;
      case EdenModalSize.lg:
        return 640;
      case EdenModalSize.xl:
        return 800;
    }
  }
}
