import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// The type of annotation placed on a document page.
enum EdenAnnotationType { highlight, note, redact }

/// A single annotation on a document page.
///
/// Coordinates in [rect] are normalised to 0–1 relative to the page size so
/// that annotations scale correctly at any zoom level.
class EdenDocumentAnnotation {
  const EdenDocumentAnnotation({
    required this.id,
    required this.page,
    required this.rect,
    this.color = const Color(0x80FFEB3B),
    this.text,
    this.type = EdenAnnotationType.highlight,
  });

  final String id;
  final int page;

  /// Left, top, width, height — all in the 0–1 range relative to page size.
  final Rect rect;
  final Color color;
  final String? text;
  final EdenAnnotationType type;

  EdenDocumentAnnotation copyWith({
    String? id,
    int? page,
    Rect? rect,
    Color? color,
    String? text,
    EdenAnnotationType? type,
  }) {
    return EdenDocumentAnnotation(
      id: id ?? this.id,
      page: page ?? this.page,
      rect: rect ?? this.rect,
      color: color ?? this.color,
      text: text ?? this.text,
      type: type ?? this.type,
    );
  }
}

/// Loading state for the document viewer.
enum EdenDocumentViewerStatus { loading, ready, error }

/// A multi-page document / image viewer with zoom, pan, annotations, a
/// thumbnail sidebar, and fullscreen toggle.
///
/// Pages are provided as a list of arbitrary [Widget]s so consumers can supply
/// any renderable content. Common page sources:
///
/// * **Images** — `Image.network(url)`, `Image.file(file)`, `Image.memory(bytes)`
/// * **PDF** — use a PDF package (e.g. `flutter_pdfview`, `syncfusion_flutter_pdfviewer`,
///   `pdfx`) and pass rendered page widgets
/// * **SVG** — use `flutter_svg` `SvgPicture` widgets
/// * **Custom** — any `Widget` (e.g. a styled `Container` with text content)
///
/// The viewer handles zoom, pan, page navigation, and annotation overlays.
/// Mouse-wheel zoom is isolated from parent scrolling — scrolling inside the
/// viewer zooms the document rather than scrolling the page.
class EdenDocumentViewer extends StatefulWidget {
  const EdenDocumentViewer({
    super.key,
    required this.pages,
    this.status = EdenDocumentViewerStatus.ready,
    this.errorMessage,
    this.initialPage = 0,
    this.annotations = const [],
    this.showThumbnails = false,
    this.thumbnailWidth = 96,
    this.minScale = 0.5,
    this.maxScale = 5.0,
    this.onPageChanged,
    this.onAnnotationTap,
    this.onAnnotationAdded,
    this.onFullscreenToggle,
    this.isFullscreen = false,
  });

  /// The list of page widgets to display.
  final List<Widget> pages;

  /// Current loading / error status.
  final EdenDocumentViewerStatus status;

  /// Optional error message shown when [status] is [EdenDocumentViewerStatus.error].
  final String? errorMessage;

  /// Zero-based index of the initial page to display.
  final int initialPage;

  /// Annotations overlaid on the pages.
  final List<EdenDocumentAnnotation> annotations;

  /// Whether to show the page-thumbnails sidebar.
  final bool showThumbnails;

  /// Width of each thumbnail in the sidebar.
  final double thumbnailWidth;

  /// Minimum scale factor for [InteractiveViewer].
  final double minScale;

  /// Maximum scale factor for [InteractiveViewer].
  final double maxScale;

  /// Called when the visible page changes.
  final ValueChanged<int>? onPageChanged;

  /// Called when the user taps an annotation.
  final ValueChanged<EdenDocumentAnnotation>? onAnnotationTap;

  /// Called after a new annotation is created by the user.
  final ValueChanged<EdenDocumentAnnotation>? onAnnotationAdded;

  /// Called when the fullscreen button is pressed.
  final VoidCallback? onFullscreenToggle;

  /// Whether the viewer is currently in fullscreen mode.
  final bool isFullscreen;

  @override
  State<EdenDocumentViewer> createState() => _EdenDocumentViewerState();
}

class _EdenDocumentViewerState extends State<EdenDocumentViewer> {
  late int _currentPage;
  late TransformationController _transformationController;
  bool _showThumbnails = false;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.clamp(0, _maxPage);
    _transformationController = TransformationController();
    _showThumbnails = widget.showThumbnails;
  }

  @override
  void didUpdateWidget(EdenDocumentViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pages.length != oldWidget.pages.length) {
      _currentPage = _currentPage.clamp(0, _maxPage);
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  int get _maxPage =>
      widget.pages.isEmpty ? 0 : widget.pages.length - 1;

  int get _totalPages => widget.pages.length;

  // ---------------------------------------------------------------------------
  // Zoom helpers
  // ---------------------------------------------------------------------------

  void _zoomIn() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale =
        (currentScale * 1.25).clamp(widget.minScale, widget.maxScale);
    _setScale(newScale);
  }

  void _zoomOut() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale =
        (currentScale / 1.25).clamp(widget.minScale, widget.maxScale);
    _setScale(newScale);
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  void _fitToWidth() {
    // Reset then let InteractiveViewer fill width (identity is fit-to-width in
    // our layout because the page widget is constrained to the available width).
    _transformationController.value = Matrix4.identity();
  }

  void _setScale(double scale) {
    final matrix = Matrix4.identity()..scaleByDouble(scale, scale, 1.0, 1.0);
    _transformationController.value = matrix;
  }

  // ---------------------------------------------------------------------------
  // Page navigation
  // ---------------------------------------------------------------------------

  void _goToPage(int page) {
    final clamped = page.clamp(0, _maxPage);
    if (clamped == _currentPage) return;
    setState(() {
      _currentPage = clamped;
      _resetZoom();
    });
    widget.onPageChanged?.call(clamped);
  }

  void _prevPage() => _goToPage(_currentPage - 1);
  void _nextPage() => _goToPage(_currentPage + 1);

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor =
        isDark ? EdenColors.neutral[900]! : EdenColors.neutral[100]!;
    final surfaceColor =
        isDark ? EdenColors.neutral[800]! : Colors.white;
    final borderColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;
    final mutedText =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: EdenRadii.borderRadiusLg,
        border: Border.all(color: borderColor),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final hasBoundedHeight = constraints.hasBoundedHeight;
          final body = _buildBody(theme, isDark, surfaceColor, borderColor, mutedText);
          final wrappedBody = hasBoundedHeight
              ? Expanded(child: body)
              : SizedBox(height: 400, child: body);
          return Column(
            mainAxisSize: hasBoundedHeight ? MainAxisSize.max : MainAxisSize.min,
            children: [
              _buildToolbar(theme, isDark, surfaceColor, borderColor, mutedText),
              wrappedBody,
              _buildPageBar(theme, isDark, surfaceColor, borderColor, mutedText),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Toolbar
  // ---------------------------------------------------------------------------

  Widget _buildToolbar(
    ThemeData theme,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color mutedText,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space3,
        vertical: EdenSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(bottom: BorderSide(color: borderColor)),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(EdenRadii.lg),
          topRight: Radius.circular(EdenRadii.lg),
        ),
      ),
      child: Row(
        children: [
          _ToolbarIconButton(
            icon: Icons.zoom_in_rounded,
            tooltip: 'Zoom in',
            onPressed: widget.status == EdenDocumentViewerStatus.ready
                ? _zoomIn
                : null,
          ),
          _ToolbarIconButton(
            icon: Icons.zoom_out_rounded,
            tooltip: 'Zoom out',
            onPressed: widget.status == EdenDocumentViewerStatus.ready
                ? _zoomOut
                : null,
          ),
          _ToolbarIconButton(
            icon: Icons.restart_alt_rounded,
            tooltip: 'Reset zoom',
            onPressed: widget.status == EdenDocumentViewerStatus.ready
                ? _resetZoom
                : null,
          ),
          _ToolbarIconButton(
            icon: Icons.fit_screen_rounded,
            tooltip: 'Fit to width',
            onPressed: widget.status == EdenDocumentViewerStatus.ready
                ? _fitToWidth
                : null,
          ),
          const SizedBox(width: EdenSpacing.space2),
          Container(width: 1, height: 20, color: borderColor),
          const SizedBox(width: EdenSpacing.space2),
          _ToolbarIconButton(
            icon: _showThumbnails
                ? Icons.view_sidebar_rounded
                : Icons.view_sidebar_outlined,
            tooltip: _showThumbnails ? 'Hide thumbnails' : 'Show thumbnails',
            onPressed: widget.status == EdenDocumentViewerStatus.ready
                ? () => setState(() => _showThumbnails = !_showThumbnails)
                : null,
          ),
          const Spacer(),
          if (widget.onFullscreenToggle != null)
            _ToolbarIconButton(
              icon: widget.isFullscreen
                  ? Icons.fullscreen_exit_rounded
                  : Icons.fullscreen_rounded,
              tooltip:
                  widget.isFullscreen ? 'Exit fullscreen' : 'Fullscreen',
              onPressed: widget.onFullscreenToggle,
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Body — viewer + optional thumbnails
  // ---------------------------------------------------------------------------

  Widget _buildBody(
    ThemeData theme,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color mutedText,
  ) {
    if (widget.status == EdenDocumentViewerStatus.loading) {
      return _buildLoadingSkeleton(isDark);
    }
    if (widget.status == EdenDocumentViewerStatus.error) {
      return _buildError(theme, mutedText);
    }
    if (widget.pages.isEmpty) {
      return Center(
        child: Text(
          'No pages to display',
          style: theme.textTheme.bodyMedium?.copyWith(color: mutedText),
        ),
      );
    }

    return Row(
      children: [
        if (_showThumbnails)
          _buildThumbnailSidebar(isDark, surfaceColor, borderColor),
        Expanded(child: _buildPageViewer(isDark)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Thumbnail sidebar
  // ---------------------------------------------------------------------------

  Widget _buildThumbnailSidebar(
    bool isDark,
    Color surfaceColor,
    Color borderColor,
  ) {
    final selectedBorder =
        isDark ? EdenColors.blue[400]! : EdenColors.blue[600]!;

    return Container(
      width: widget.thumbnailWidth + EdenSpacing.space4 * 2,
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(right: BorderSide(color: borderColor)),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          vertical: EdenSpacing.space3,
          horizontal: EdenSpacing.space4,
        ),
        itemCount: _totalPages,
        itemBuilder: (context, index) {
          final isSelected = index == _currentPage;
          return Padding(
            padding: const EdgeInsets.only(bottom: EdenSpacing.space2),
            child: Semantics(
              button: true,
              label: 'Go to page ${index + 1}',
              child: GestureDetector(
              onTap: () => _goToPage(index),
              child: Container(
                width: widget.thumbnailWidth,
                height: widget.thumbnailWidth * 1.4,
                decoration: BoxDecoration(
                  borderRadius: EdenRadii.borderRadiusSm,
                  border: Border.all(
                    color: isSelected ? selectedBorder : borderColor,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: 200,
                    height: 280,
                    child: IgnorePointer(child: widget.pages[index]),
                  ),
                ),
              ),
            ),
          ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Page viewer (interactive zoom / pan + annotation overlay)
  // ---------------------------------------------------------------------------

  /// Handles pointer scroll signals (mouse wheel) inside the viewer by
  /// converting them to zoom operations instead of letting them propagate
  /// to the parent scrollable.
  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      // Consume the scroll event — prevent parent from scrolling.
      GestureBinding.instance.pointerSignalResolver.register(
        event,
        (PointerSignalEvent e) {
          if (e is PointerScrollEvent) {
            final delta = e.scrollDelta.dy;
            final currentScale =
                _transformationController.value.getMaxScaleOnAxis();
            // Scroll up = zoom in, scroll down = zoom out.
            final scaleFactor = delta < 0 ? 1.1 : 0.9;
            final newScale =
                (currentScale * scaleFactor).clamp(widget.minScale, widget.maxScale);

            // Scale around the pointer position for natural zoom behaviour.
            final renderBox = context.findRenderObject() as RenderBox?;
            if (renderBox != null) {
              final local = renderBox.globalToLocal(e.position);
              final focalPoint = local;

              // Compute the new matrix: translate to focal → scale → translate back.
              final dx = focalPoint.dx;
              final dy = focalPoint.dy;
              final scaleChange = newScale / currentScale;

              final matrix = _transformationController.value.clone();
              matrix
                ..translateByDouble(dx, dy, 0, 1)
                ..scaleByDouble(scaleChange, scaleChange, 1, 1)
                ..translateByDouble(-dx, -dy, 0, 1);

              // Clamp the resulting scale.
              final resultScale = matrix.getMaxScaleOnAxis();
              if (resultScale >= widget.minScale &&
                  resultScale <= widget.maxScale) {
                _transformationController.value = matrix;
              }
            }
          }
        },
      );
    }
  }

  Widget _buildPageViewer(bool isDark) {
    return ClipRect(
      child: Listener(
        onPointerSignal: _handlePointerSignal,
        child: InteractiveViewer(
          transformationController: _transformationController,
          minScale: widget.minScale,
          maxScale: widget.maxScale,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    widget.pages[_currentPage],
                    ..._buildAnnotationOverlays(constraints),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAnnotationOverlays(BoxConstraints constraints) {
    final pageAnnotations = widget.annotations
        .where((a) => a.page == _currentPage)
        .toList();

    if (pageAnnotations.isEmpty) return [];

    // We use a Positioned.fill + CustomPaint approach so that annotations
    // scale with the page content inside the InteractiveViewer.
    return pageAnnotations.map((annotation) {
      return Positioned.fill(
        child: LayoutBuilder(
          builder: (context, innerConstraints) {
            final w = innerConstraints.maxWidth;
            final h = innerConstraints.maxHeight;
            return Stack(
              children: [
                Positioned(
                  left: annotation.rect.left * w,
                  top: annotation.rect.top * h,
                  width: annotation.rect.width * w,
                  height: annotation.rect.height * h,
                  child: Semantics(
                    button: widget.onAnnotationTap != null,
                    label: annotation.text ?? 'Annotation',
                    child: GestureDetector(
                      onTap: () =>
                          widget.onAnnotationTap?.call(annotation),
                      child: _AnnotationWidget(annotation: annotation),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Page bar (prev / next / page number)
  // ---------------------------------------------------------------------------

  Widget _buildPageBar(
    ThemeData theme,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color mutedText,
  ) {
    if (widget.status != EdenDocumentViewerStatus.ready ||
        widget.pages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space3,
        vertical: EdenSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(top: BorderSide(color: borderColor)),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(EdenRadii.lg),
          bottomRight: Radius.circular(EdenRadii.lg),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ToolbarIconButton(
            icon: Icons.chevron_left_rounded,
            tooltip: 'Previous page',
            onPressed: _currentPage > 0 ? _prevPage : null,
          ),
          const SizedBox(width: EdenSpacing.space2),
          Text(
            'Page ${_currentPage + 1} of $_totalPages',
            style: theme.textTheme.bodySmall?.copyWith(color: mutedText),
          ),
          const SizedBox(width: EdenSpacing.space2),
          _ToolbarIconButton(
            icon: Icons.chevron_right_rounded,
            tooltip: 'Next page',
            onPressed: _currentPage < _maxPage ? _nextPage : null,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Loading skeleton
  // ---------------------------------------------------------------------------

  Widget _buildLoadingSkeleton(bool isDark) {
    final shimmer =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EdenSpacing.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 280,
              height: 360,
              decoration: BoxDecoration(
                color: shimmer,
                borderRadius: EdenRadii.borderRadiusMd,
              ),
            ),
            const SizedBox(height: EdenSpacing.space4),
            Container(
              width: 120,
              height: 12,
              decoration: BoxDecoration(
                color: shimmer,
                borderRadius: EdenRadii.borderRadiusSm,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Error state
  // ---------------------------------------------------------------------------

  Widget _buildError(ThemeData theme, Color mutedText) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EdenSpacing.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: EdenColors.error),
            const SizedBox(height: EdenSpacing.space3),
            Text(
              widget.errorMessage ?? 'Failed to load document',
              style: theme.textTheme.bodyMedium?.copyWith(color: mutedText),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Private helpers
// =============================================================================

/// A small icon button used in the toolbar and page bar.
class _ToolbarIconButton extends StatelessWidget {
  const _ToolbarIconButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = onPressed == null
        ? (isDark ? EdenColors.neutral[600]! : EdenColors.neutral[300]!)
        : (isDark ? EdenColors.neutral[300]! : EdenColors.neutral[600]!);

    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: EdenRadii.borderRadiusSm,
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(EdenSpacing.space1),
              child: Icon(icon, size: 20, color: color),
            ),
          ),
        ),
      ),
    );
  }
}

/// Renders a single annotation overlay on the page.
class _AnnotationWidget extends StatelessWidget {
  const _AnnotationWidget({required this.annotation});

  final EdenDocumentAnnotation annotation;

  @override
  Widget build(BuildContext context) {
    switch (annotation.type) {
      case EdenAnnotationType.highlight:
        return Container(
          decoration: BoxDecoration(
            color: annotation.color.withValues(alpha: 0.30),
            border: Border.all(
              color: annotation.color.withValues(alpha: 0.60),
              width: 1.5,
            ),
            borderRadius: EdenRadii.borderRadiusSm,
          ),
        );
      case EdenAnnotationType.note:
        return Container(
          decoration: BoxDecoration(
            color: annotation.color.withValues(alpha: 0.15),
            border: Border.all(
              color: annotation.color.withValues(alpha: 0.50),
            ),
            borderRadius: EdenRadii.borderRadiusSm,
          ),
          padding: const EdgeInsets.all(EdenSpacing.space1),
          child: annotation.text != null
              ? Text(
                  annotation.text!,
                  style: TextStyle(
                    fontSize: 10,
                    color: annotation.color.withValues(alpha: 0.90),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                )
              : Icon(
                  Icons.sticky_note_2_outlined,
                  size: 14,
                  color: annotation.color.withValues(alpha: 0.80),
                ),
        );
      case EdenAnnotationType.redact:
        return Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: EdenRadii.borderRadiusSm,
          ),
        );
    }
  }
}
