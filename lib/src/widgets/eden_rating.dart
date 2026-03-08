import 'package:flutter/material.dart';

/// Size presets for rating stars.
enum EdenRatingSize { sm, md, lg }

/// Mirrors the eden_rating Rails component.
class EdenRating extends StatelessWidget {
  const EdenRating({
    super.key,
    required this.value,
    this.max = 5,
    this.size = EdenRatingSize.md,
    this.onChanged,
  });

  /// Current rating value (supports half values like 3.5).
  final double value;
  final int max;
  final EdenRatingSize size;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    final starSize = _resolveSize();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(max, (i) {
        final starValue = i + 1;
        final isFull = value >= starValue;
        final isHalf = !isFull && value >= starValue - 0.5;

        return GestureDetector(
          onTap: onChanged != null ? () => onChanged!(starValue.toDouble()) : null,
          child: Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Icon(
              isFull
                  ? Icons.star_rounded
                  : isHalf
                      ? Icons.star_half_rounded
                      : Icons.star_outline_rounded,
              size: starSize,
              color: isFull || isHalf
                  ? const Color(0xFFFCD34D) // yellow-300
                  : Colors.grey[400],
            ),
          ),
        );
      }),
    );
  }

  double _resolveSize() {
    switch (size) {
      case EdenRatingSize.sm:
        return 18;
      case EdenRatingSize.md:
        return 24;
      case EdenRatingSize.lg:
        return 32;
    }
  }
}
