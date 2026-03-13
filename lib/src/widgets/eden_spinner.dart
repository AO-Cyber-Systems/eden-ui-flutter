import 'package:flutter/material.dart';

/// Spinner size presets.
enum EdenSpinnerSize { sm, md, lg }

/// Mirrors the eden_spinner Rails component.
///
/// Supports both indeterminate (default) and determinate progress.
/// Pass [value] (0.0–1.0) for a determinate progress indicator.
class EdenSpinner extends StatelessWidget {
  const EdenSpinner({
    super.key,
    this.size = EdenSpinnerSize.md,
    this.color,
    this.value,
  });

  final EdenSpinnerSize size;
  final Color? color;

  /// If non-null, displays a determinate progress indicator (0.0–1.0).
  final double? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dimension = _resolveDimension();

    return SizedBox(
      width: dimension,
      height: dimension,
      child: CircularProgressIndicator(
        value: value,
        strokeWidth: dimension > 24 ? 3 : 2,
        color: color ?? theme.colorScheme.primary,
      ),
    );
  }

  double _resolveDimension() {
    switch (size) {
      case EdenSpinnerSize.sm:
        return 16;
      case EdenSpinnerSize.md:
        return 24;
      case EdenSpinnerSize.lg:
        return 36;
    }
  }
}
