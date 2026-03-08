import 'package:flutter/material.dart';
import '../tokens/spacing.dart';

/// Drawer position.
enum EdenDrawerPosition { left, right }

/// Mirrors the eden_drawer Rails component.
///
/// A side panel that slides in from the left or right.
/// Use [EdenDrawerPanel.show] to display.
class EdenDrawerPanel {
  EdenDrawerPanel._();

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    String? title,
    EdenDrawerPosition position = EdenDrawerPosition.right,
    double width = 360,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: position == EdenDrawerPosition.right
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: _EdenDrawerContent(
            title: title,
            width: width,
            position: position,
            child: child,
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final offset = position == EdenDrawerPosition.right
            ? Offset(1.0 - animation.value, 0)
            : Offset(animation.value - 1.0, 0);
        return FractionalTranslation(translation: offset, child: child);
      },
    );
  }
}

class _EdenDrawerContent extends StatelessWidget {
  const _EdenDrawerContent({
    required this.child,
    this.title,
    required this.width,
    required this.position,
  });

  final Widget child;
  final String? title;
  final double width;
  final EdenDrawerPosition position;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: 16,
      child: Container(
        width: width,
        height: double.infinity,
        color: theme.colorScheme.surface,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null)
                Padding(
                  padding: const EdgeInsets.all(EdenSpacing.space4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(title!, style: theme.textTheme.titleLarge),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Icon(
                          Icons.close,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              if (title != null)
                Divider(height: 1, color: theme.colorScheme.outlineVariant),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
