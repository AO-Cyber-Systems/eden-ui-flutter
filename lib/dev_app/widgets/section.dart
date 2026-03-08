import 'package:flutter/material.dart';
import '../../eden_ui.dart';

/// A labeled section wrapper used throughout the dev catalog.
class Section extends StatelessWidget {
  const Section({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: EdenSpacing.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          )),
          const SizedBox(height: EdenSpacing.space2),
          child,
        ],
      ),
    );
  }
}
