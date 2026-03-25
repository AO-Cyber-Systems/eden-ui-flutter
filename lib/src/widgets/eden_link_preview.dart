import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// An OpenGraph-style URL preview card with optional image, title, and description.
class EdenLinkPreview extends StatelessWidget {
  const EdenLinkPreview({
    super.key,
    required this.title,
    this.description,
    this.siteName,
    this.imageUrl,
    this.image,
    this.onTap,
  });

  final String title;
  final String? description;
  final String? siteName;
  final String? imageUrl;
  final ImageProvider? image;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? EdenColors.neutral[800] : EdenColors.neutral[50],
          borderRadius: EdenRadii.borderRadiusMd,
          border: Border.all(
            color: isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            _buildImage(isDark),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EdenSpacing.space3,
                  vertical: EdenSpacing.space2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (siteName != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          siteName!,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? EdenColors.neutral[400]
                                : EdenColors.neutral[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (description != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          description!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? EdenColors.neutral[400]
                                : EdenColors.neutral[500],
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(bool isDark) {
    if (image != null) {
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(EdenRadii.md),
          bottomLeft: Radius.circular(EdenRadii.md),
        ),
        child: Image(
          image: image!,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: 80,
      height: 80,
      color: isDark
          ? EdenColors.neutral[700]
          : EdenColors.neutral[100],
      child: Icon(
        Icons.language,
        size: 28,
        color: isDark ? EdenColors.neutral[500] : EdenColors.neutral[400],
      ),
    );
  }
}
