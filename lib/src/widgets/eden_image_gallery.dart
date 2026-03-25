import 'package:flutter/material.dart';
import '../tokens/spacing.dart';
import '../tokens/radii.dart';

/// An image gallery item.
class EdenGalleryImage {
  const EdenGalleryImage({
    this.image,
    this.url,
    this.caption,
  }) : assert(image != null || url != null, 'Either image or url must be provided');

  /// A widget-based image (e.g., Image.asset, Image.network).
  final Widget? image;

  /// A URL to load via Image.network. Used when [image] is null.
  final String? url;

  /// Optional caption displayed in the lightbox.
  final String? caption;
}

/// A grid of images with tap-to-expand lightbox overlay.
///
/// Displays images in a responsive grid. Tapping an image opens a
/// full-screen lightbox with left/right navigation.
class EdenImageGallery extends StatelessWidget {
  const EdenImageGallery({
    super.key,
    required this.images,
    this.crossAxisCount = 3,
    this.spacing = EdenSpacing.space2,
    this.borderRadius,
  });

  /// List of images to display.
  final List<EdenGalleryImage> images;

  /// Number of columns in the grid.
  final int crossAxisCount;

  /// Spacing between grid items.
  final double spacing;

  /// Border radius for grid thumbnails.
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _openLightbox(context, index),
          child: ClipRRect(
            borderRadius: borderRadius ?? EdenRadii.borderRadiusMd,
            child: _buildThumbnail(images[index]),
          ),
        );
      },
    );
  }

  Widget _buildThumbnail(EdenGalleryImage item) {
    if (item.image != null) {
      return SizedBox.expand(child: FittedBox(fit: BoxFit.cover, child: item.image!));
    }
    return Image.network(
      item.url!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }

  void _openLightbox(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _LightboxOverlay(
            images: images,
            initialIndex: initialIndex,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

class _LightboxOverlay extends StatefulWidget {
  const _LightboxOverlay({
    required this.images,
    required this.initialIndex,
  });

  final List<EdenGalleryImage> images;
  final int initialIndex;

  @override
  State<_LightboxOverlay> createState() => _LightboxOverlayState();
}

class _LightboxOverlayState extends State<_LightboxOverlay> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.images[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Stack(
          children: [
            // Image pages
            PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (context, index) {
                final img = widget.images[index];
                return Center(
                  child: GestureDetector(
                    onTap: () {}, // prevent close when tapping image
                    child: Padding(
                      padding: const EdgeInsets.all(EdenSpacing.space8),
                      child: img.image ??
                          Image.network(
                            img.url!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image,
                              color: Colors.white54,
                              size: 64,
                            ),
                          ),
                    ),
                  ),
                );
              },
            ),
            // Close button
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            // Caption
            if (item.caption != null)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 24,
                left: 24,
                right: 24,
                child: Text(
                  item.caption!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            // Navigation arrows
            if (widget.images.length > 1) ...[
              if (_currentIndex > 0)
                Positioned(
                  left: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left,
                          color: Colors.white70, size: 36),
                      onPressed: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                    ),
                  ),
                ),
              if (_currentIndex < widget.images.length - 1)
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      icon: const Icon(Icons.chevron_right,
                          color: Colors.white70, size: 36),
                      onPressed: () => _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                    ),
                  ),
                ),
              // Page indicator
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 8,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${_currentIndex + 1} / ${widget.images.length}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
