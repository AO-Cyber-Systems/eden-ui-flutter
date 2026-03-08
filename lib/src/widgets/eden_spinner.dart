import 'package:flutter/material.dart';

/// Spinner size presets.
enum EdenSpinnerSize { sm, md, lg }

/// Mirrors the eden_spinner Rails component.
class EdenSpinner extends StatelessWidget {
  const EdenSpinner({
    super.key,
    this.size = EdenSpinnerSize.md,
    this.color,
  });

  final EdenSpinnerSize size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dimension = _resolveDimension();

    return SizedBox(
      width: dimension,
      height: dimension,
      child: CircularProgressIndicator(
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
