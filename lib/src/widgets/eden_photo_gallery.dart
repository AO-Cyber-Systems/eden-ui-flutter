import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Represents a photo in the gallery.
class EdenPhoto {
  /// Creates a photo model.
  const EdenPhoto({
    required this.id,
    this.url,
    this.imageProvider,
    this.thumbnailUrl,
    this.thumbnailProvider,
    this.caption,
    this.timestamp,
    this.metadata = const {},
  }) : assert(
          url != null || imageProvider != null,
          'Either url or imageProvider must be provided',
        );

  /// Unique identifier.
  final String id;

  /// Full-size image URL.
  final String? url;

  /// Full-size image provider (takes precedence over [url]).
  final ImageProvider? imageProvider;

  /// Thumbnail URL for grid display.
  final String? thumbnailUrl;

  /// Thumbnail image provider (takes precedence over [thumbnailUrl]).
  final ImageProvider? thumbnailProvider;

  /// Optional caption text.
  final String? caption;

  /// When the photo was taken or added.
  final DateTime? timestamp;

  /// Arbitrary key-value metadata (location, device, etc.).
  final Map<String, String> metadata;

  /// Resolves the full-size [ImageProvider].
  ImageProvider get resolvedImage =>
      imageProvider ?? NetworkImage(url!);

  /// Resolves the thumbnail [ImageProvider], falling back to full image.
  ImageProvider get resolvedThumbnail =>
      thumbnailProvider ??
      (thumbnailUrl != null ? NetworkImage(thumbnailUrl!) : resolvedImage);
}

/// Display mode for the photo gallery.
enum EdenPhotoGalleryMode {
  /// Standard grid layout.
  grid,

  /// Horizontal scrolling strip of thumbnails.
  strip,
}

/// A photo gallery widget with lightbox viewer, selection mode, and strip
/// variant. Designed for field service photo management workflows.
class EdenPhotoGallery extends StatefulWidget {
  /// Creates a photo gallery.
  const EdenPhotoGallery({
    super.key,
    required this.photos,
    this.mode = EdenPhotoGalleryMode.grid,
    this.columnCount = 3,
    this.stripHeight = 96,
    this.enableSelection = true,
    this.showAddButton = true,
    this.onPhotoTap,
    this.onAddPhoto,
    this.onDeletePhotos,
    this.onSelectionChanged,
    this.emptyStateMessage = 'No photos',
  });

  /// The list of photos to display.
  final List<EdenPhoto> photos;

  /// Display mode: grid or horizontal strip.
  final EdenPhotoGalleryMode mode;

  /// Number of columns in grid mode (2, 3, or 4).
  final int columnCount;

  /// Height of the strip in [EdenPhotoGalleryMode.strip] mode.
  final double stripHeight;

  /// Whether long-press selection is enabled.
  final bool enableSelection;

  /// Whether to show the add-photo button tile.
  final bool showAddButton;

  /// Called when a photo is tapped (outside of selection mode).
  final ValueChanged<EdenPhoto>? onPhotoTap;

  /// Called when the add-photo button is tapped.
  final VoidCallback? onAddPhoto;

  /// Called when the delete action is confirmed with the selected photo IDs.
  final ValueChanged<Set<String>>? onDeletePhotos;

  /// Called whenever the selection set changes.
  final ValueChanged<Set<String>>? onSelectionChanged;

  /// Message shown in the empty state.
  final String emptyStateMessage;

  @override
  State<EdenPhotoGallery> createState() => _EdenPhotoGalleryState();
}

class _EdenPhotoGalleryState extends State<EdenPhotoGallery> {
  final Set<String> _selected = {};
  bool _selectionMode = false;

  void _toggleSelection(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
        if (_selected.isEmpty) _selectionMode = false;
      } else {
        _selected.add(id);
      }
    });
    widget.onSelectionChanged?.call(Set.unmodifiable(_selected));
  }

  void _enterSelectionMode(String id) {
    if (!widget.enableSelection) return;
    setState(() {
      _selectionMode = true;
      _selected.add(id);
    });
    widget.onSelectionChanged?.call(Set.unmodifiable(_selected));
  }

  void _clearSelection() {
    setState(() {
      _selected.clear();
      _selectionMode = false;
    });
    widget.onSelectionChanged?.call(Set.unmodifiable(_selected));
  }

  void _deleteSelected() {
    widget.onDeletePhotos?.call(Set.unmodifiable(_selected));
    _clearSelection();
  }

  void _openLightbox(int index) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _EdenLightbox(
            photos: widget.photos,
            initialIndex: index,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (widget.photos.isEmpty && !widget.showAddButton) {
      return _EmptyState(
        message: widget.emptyStateMessage,
        isDark: isDark,
        theme: theme,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Selection toolbar
        if (_selectionMode)
          _SelectionToolbar(
            count: _selected.length,
            onClear: _clearSelection,
            onDelete: widget.onDeletePhotos != null ? _deleteSelected : null,
            isDark: isDark,
            theme: theme,
          ),

        // Gallery content
        if (widget.photos.isEmpty && widget.showAddButton)
          _EmptyState(
            message: widget.emptyStateMessage,
            isDark: isDark,
            theme: theme,
            onAdd: widget.onAddPhoto,
          )
        else if (widget.mode == EdenPhotoGalleryMode.strip)
          _buildStrip(isDark)
        else
          _buildGrid(isDark),
      ],
    );
  }

  Widget _buildGrid(bool isDark) {
    final itemCount =
        widget.photos.length + (widget.showAddButton ? 1 : 0);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.columnCount.clamp(2, 4),
        crossAxisSpacing: EdenSpacing.space2,
        mainAxisSpacing: EdenSpacing.space2,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == widget.photos.length && widget.showAddButton) {
          return _AddPhotoTile(
            onTap: widget.onAddPhoto,
            isDark: isDark,
          );
        }

        final photo = widget.photos[index];
        return _PhotoTile(
          photo: photo,
          isSelected: _selected.contains(photo.id),
          selectionMode: _selectionMode,
          onTap: () {
            if (_selectionMode) {
              _toggleSelection(photo.id);
            } else {
              widget.onPhotoTap?.call(photo);
              _openLightbox(index);
            }
          },
          onLongPress: () => _enterSelectionMode(photo.id),
          isDark: isDark,
        );
      },
    );
  }

  Widget _buildStrip(bool isDark) {
    final itemCount =
        widget.photos.length + (widget.showAddButton ? 1 : 0);

    return SizedBox(
      height: widget.stripHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(width: EdenSpacing.space2),
        itemBuilder: (context, index) {
          if (index == widget.photos.length && widget.showAddButton) {
            return SizedBox(
              width: widget.stripHeight,
              height: widget.stripHeight,
              child: _AddPhotoTile(onTap: widget.onAddPhoto, isDark: isDark),
            );
          }

          final photo = widget.photos[index];
          return SizedBox(
            width: widget.stripHeight,
            height: widget.stripHeight,
            child: _PhotoTile(
              photo: photo,
              isSelected: _selected.contains(photo.id),
              selectionMode: _selectionMode,
              onTap: () {
                if (_selectionMode) {
                  _toggleSelection(photo.id);
                } else {
                  widget.onPhotoTap?.call(photo);
                  _openLightbox(index);
                }
              },
              onLongPress: () => _enterSelectionMode(photo.id),
              isDark: isDark,
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Photo tile
// ---------------------------------------------------------------------------

class _PhotoTile extends StatefulWidget {
  const _PhotoTile({
    required this.photo,
    required this.isSelected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.isDark,
  });

  final EdenPhoto photo;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isDark;

  @override
  State<_PhotoTile> createState() => _PhotoTileState();
}

class _PhotoTileState extends State<_PhotoTile> {
  bool _loaded = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isSelected
        ? Theme.of(context).colorScheme.primary
        : widget.isDark
            ? EdenColors.neutral[700]!
            : EdenColors.neutral[200]!;

    return Semantics(
      button: true,
      label: widget.photo.caption ?? 'Photo',
      child: GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: EdenRadii.borderRadiusMd,
          border: Border.all(
            color: borderColor,
            width: widget.isSelected ? 2.5 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            widget.isSelected ? EdenRadii.md - 1.5 : EdenRadii.md - 1,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Skeleton placeholder
              if (!_loaded)
                _SkeletonShimmer(isDark: widget.isDark),

              // Image
              Image(
                image: widget.photo.resolvedThumbnail,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded || frame != null) {
                    if (!_loaded) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _loaded = true);
                      });
                    }
                    return child;
                  }
                  return const SizedBox.shrink();
                },
                errorBuilder: (_, __, ___) {
                  return Container(
                    color: widget.isDark
                        ? EdenColors.neutral[800]
                        : EdenColors.neutral[100],
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: EdenColors.neutral[400],
                      size: 32,
                    ),
                  );
                },
              ),

              // Selection checkbox
              if (widget.selectionMode)
                Positioned(
                  top: EdenSpacing.space1,
                  right: EdenSpacing.space1,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.black45,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: widget.isSelected
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ),

              // Caption overlay
              if (widget.photo.caption != null && !widget.selectionMode)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: EdenSpacing.space1,
                      vertical: EdenSpacing.space1 / 2,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                    child: Text(
                      widget.photo.caption!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton shimmer
// ---------------------------------------------------------------------------

class _SkeletonShimmer extends StatefulWidget {
  const _SkeletonShimmer({required this.isDark});

  final bool isDark;

  @override
  State<_SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<_SkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor =
        widget.isDark ? EdenColors.neutral[800]! : EdenColors.neutral[200]!;
    final highlightColor =
        widget.isDark ? EdenColors.neutral[700]! : EdenColors.neutral[100]!;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value,
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Add photo tile
// ---------------------------------------------------------------------------

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({
    required this.isDark,
    this.onTap,
  });

  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor =
        isDark ? EdenColors.neutral[800]! : EdenColors.neutral[100]!;
    final borderColor =
        isDark ? EdenColors.neutral[600]! : EdenColors.neutral[300]!;
    final iconColor =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;

    return Semantics(
      button: true,
      label: 'Add photo',
      child: Material(
        color: bgColor,
        borderRadius: EdenRadii.borderRadiusMd,
        child: InkWell(
          onTap: onTap,
          borderRadius: EdenRadii.borderRadiusMd,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: EdenRadii.borderRadiusMd,
              border: Border.all(color: borderColor, style: BorderStyle.solid),
            ),
            child: Center(
              child: Icon(Icons.add_a_photo_outlined, color: iconColor, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Selection toolbar
// ---------------------------------------------------------------------------

class _SelectionToolbar extends StatelessWidget {
  const _SelectionToolbar({
    required this.count,
    required this.onClear,
    required this.isDark,
    required this.theme,
    this.onDelete,
  });

  final int count;
  final VoidCallback onClear;
  final VoidCallback? onDelete;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final bgColor =
        isDark ? EdenColors.neutral[800]! : EdenColors.neutral[100]!;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space3,
        vertical: EdenSpacing.space2,
      ),
      margin: const EdgeInsets.only(bottom: EdenSpacing.space2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: EdenRadii.borderRadiusMd,
      ),
      child: Row(
        children: [
          Text(
            '$count selected',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (onDelete != null)
            TextButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 18, color: EdenColors.error),
              label: const Text(
                'Delete',
                style: TextStyle(color: EdenColors.error),
              ),
            ),
          const SizedBox(width: EdenSpacing.space1),
          TextButton(
            onPressed: onClear,
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.message,
    required this.isDark,
    required this.theme,
    this.onAdd,
  });

  final String message;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final iconColor =
        isDark ? EdenColors.neutral[500]! : EdenColors.neutral[400]!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: EdenSpacing.space12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.camera_alt_outlined, size: 48, color: iconColor),
            const SizedBox(height: EdenSpacing.space3),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(color: iconColor),
            ),
            if (onAdd != null) ...[
              const SizedBox(height: EdenSpacing.space4),
              OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                label: const Text('Add photo'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lightbox / full-screen viewer
// ---------------------------------------------------------------------------

class _EdenLightbox extends StatefulWidget {
  const _EdenLightbox({
    required this.photos,
    required this.initialIndex,
  });

  final List<EdenPhoto> photos;
  final int initialIndex;

  @override
  State<_EdenLightbox> createState() => _EdenLightboxState();
}

class _EdenLightboxState extends State<_EdenLightbox> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photos[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Swipeable pages with zoom
          PageView.builder(
            controller: _pageController,
            itemCount: widget.photos.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: Center(
                  child: Image(
                    image: widget.photos[index].resolvedImage,
                    fit: BoxFit.contain,
                    semanticLabel: widget.photos[index].caption ?? 'Photo ${index + 1}',
                    errorBuilder: (_, __, ___) {
                      return Icon(
                        Icons.broken_image_outlined,
                        color: EdenColors.neutral[400],
                        size: 64,
                      );
                    },
                  ),
                ),
              );
            },
          ),

          // Top bar: close button + counter
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: EdenSpacing.space3,
                  vertical: EdenSpacing.space2,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                      tooltip: 'Close',
                    ),
                    const Spacer(),
                    Text(
                      '${_currentIndex + 1} of ${widget.photos.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    // Invisible spacer to center the counter
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),

          // Bottom bar: caption
          if (photo.caption != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: EdenSpacing.space4,
                    vertical: EdenSpacing.space3,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                  child: Text(
                    photo.caption!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

          // Navigation arrows (for non-touch / desktop)
          if (_currentIndex > 0)
            Positioned(
              left: EdenSpacing.space2,
              top: 0,
              bottom: 0,
              child: Center(
                child: _NavArrow(
                  icon: Icons.chevron_left,
                  onTap: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
            ),
          if (_currentIndex < widget.photos.length - 1)
            Positioned(
              right: EdenSpacing.space2,
              top: 0,
              bottom: 0,
              child: Center(
                child: _NavArrow(
                  icon: Icons.chevron_right,
                  onTap: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: icon == Icons.chevron_left ? 'Previous photo' : 'Next photo',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: EdenRadii.borderRadiusFull,
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
