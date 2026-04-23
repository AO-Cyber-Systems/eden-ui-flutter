import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Comparison mode for the design diff viewer.
enum EdenDiffViewerMode {
  /// Two panels shown side by side.
  sideBySide,

  /// Swipe divider reveals before/after.
  overlay,

  /// Opacity slider blends before and after.
  onionSkin,
}

/// An image comparison viewer with side-by-side, overlay, and onion-skin modes.
///
/// Takes two widgets (before/after) and provides mode toggle buttons,
/// an opacity slider for onion skin mode, a swipe divider for overlay mode,
/// and zoom controls.
class EdenDesignDiffViewer extends StatefulWidget {
  /// Creates an Eden design diff viewer.
  const EdenDesignDiffViewer({
    super.key,
    required this.before,
    required this.after,
    this.initialMode = EdenDiffViewerMode.sideBySide,
    this.beforeLabel = 'Before',
    this.afterLabel = 'After',
    this.onModeChanged,
  });

  /// The before (original) widget to display.
  final Widget before;

  /// The after (changed) widget to display.
  final Widget after;

  /// Initial comparison mode.
  final EdenDiffViewerMode initialMode;

  /// Label for the before panel.
  final String beforeLabel;

  /// Label for the after panel.
  final String afterLabel;

  /// Called when the comparison mode changes.
  final ValueChanged<EdenDiffViewerMode>? onModeChanged;

  @override
  State<EdenDesignDiffViewer> createState() => _EdenDesignDiffViewerState();
}

class _EdenDesignDiffViewerState extends State<EdenDesignDiffViewer> {
  late EdenDiffViewerMode _mode;
  double _onionSkinOpacity = 0.5;
  double _overlayPosition = 0.5;
  double _zoom = 1.0;

  static const double _minZoom = 0.25;
  static const double _maxZoom = 4.0;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  void _setMode(EdenDiffViewerMode mode) {
    setState(() => _mode = mode);
    widget.onModeChanged?.call(mode);
  }

  void _zoomIn() {
    setState(() => _zoom = (_zoom * 1.25).clamp(_minZoom, _maxZoom));
  }

  void _zoomOut() {
    setState(() => _zoom = (_zoom / 1.25).clamp(_minZoom, _maxZoom));
  }

  void _zoomReset() {
    setState(() => _zoom = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final surfaceColor =
        isDark ? EdenColors.neutral[900]! : EdenColors.neutral[50]!;
    final borderColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;
    final mutedText =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border.all(color: borderColor),
        borderRadius: EdenRadii.borderRadiusLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Toolbar: mode toggle + zoom controls
          _buildToolbar(theme, isDark, borderColor, mutedText),
          Divider(height: 1, color: borderColor),

          // Onion skin slider
          if (_mode == EdenDiffViewerMode.onionSkin) ...[
            _buildOnionSkinSlider(theme, mutedText),
            Divider(height: 1, color: borderColor),
          ],

          // Content area
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(EdenRadii.lg),
              bottomRight: Radius.circular(EdenRadii.lg),
            ),
            child: _buildContent(theme, isDark, borderColor, mutedText),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(
    ThemeData theme,
    bool isDark,
    Color borderColor,
    Color mutedText,
  ) {
    final activeBg = EdenColors.info.withValues(alpha: 0.12);
    const activeColor = EdenColors.info;
    final inactiveColor = mutedText;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space3,
        vertical: EdenSpacing.space2,
      ),
      child: Row(
        children: [
          // Mode toggles
          _ModeButton(
            icon: Icons.view_column_outlined,
            label: 'Side by Side',
            isActive: _mode == EdenDiffViewerMode.sideBySide,
            activeColor: activeColor,
            activeBg: activeBg,
            inactiveColor: inactiveColor,
            onTap: () => _setMode(EdenDiffViewerMode.sideBySide),
          ),
          const SizedBox(width: EdenSpacing.space1),
          _ModeButton(
            icon: Icons.compare_outlined,
            label: 'Overlay',
            isActive: _mode == EdenDiffViewerMode.overlay,
            activeColor: activeColor,
            activeBg: activeBg,
            inactiveColor: inactiveColor,
            onTap: () => _setMode(EdenDiffViewerMode.overlay),
          ),
          const SizedBox(width: EdenSpacing.space1),
          _ModeButton(
            icon: Icons.layers_outlined,
            label: 'Onion Skin',
            isActive: _mode == EdenDiffViewerMode.onionSkin,
            activeColor: activeColor,
            activeBg: activeBg,
            inactiveColor: inactiveColor,
            onTap: () => _setMode(EdenDiffViewerMode.onionSkin),
          ),
          const Spacer(),
          // Zoom controls
          _ZoomButton(
            icon: Icons.remove,
            tooltip: 'Zoom out',
            onTap: _zoomOut,
            color: mutedText,
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: EdenSpacing.space1),
            child: GestureDetector(
              onTap: _zoomReset,
              child: Text(
                '${(_zoom * 100).round()}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: mutedText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          _ZoomButton(
            icon: Icons.add,
            tooltip: 'Zoom in',
            onTap: _zoomIn,
            color: mutedText,
          ),
        ],
      ),
    );
  }

  Widget _buildOnionSkinSlider(ThemeData theme, Color mutedText) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space4,
        vertical: EdenSpacing.space2,
      ),
      child: Row(
        children: [
          Text(
            widget.beforeLabel,
            style: theme.textTheme.bodySmall?.copyWith(color: mutedText),
          ),
          Expanded(
            child: Slider(
              value: _onionSkinOpacity,
              onChanged: (value) =>
                  setState(() => _onionSkinOpacity = value),
              activeColor: EdenColors.info,
            ),
          ),
          Text(
            widget.afterLabel,
            style: theme.textTheme.bodySmall?.copyWith(color: mutedText),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    ThemeData theme,
    bool isDark,
    Color borderColor,
    Color mutedText,
  ) {
    switch (_mode) {
      case EdenDiffViewerMode.sideBySide:
        return _buildSideBySide(theme, isDark, borderColor, mutedText);
      case EdenDiffViewerMode.overlay:
        return _buildOverlay(theme, isDark, mutedText);
      case EdenDiffViewerMode.onionSkin:
        return _buildOnionSkin();
    }
  }

  Widget _buildSideBySide(
    ThemeData theme,
    bool isDark,
    Color borderColor,
    Color mutedText,
  ) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildPanel(
              label: widget.beforeLabel,
              child: widget.before,
              theme: theme,
              mutedText: mutedText,
            ),
          ),
          VerticalDivider(width: 1, color: borderColor),
          Expanded(
            child: _buildPanel(
              label: widget.afterLabel,
              child: widget.after,
              theme: theme,
              mutedText: mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanel({
    required String label,
    required Widget child,
    required ThemeData theme,
    required Color mutedText,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(EdenSpacing.space2),
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: mutedText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Transform.scale(
              scale: _zoom,
              child: child,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverlay(ThemeData theme, bool isDark, Color mutedText) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              _overlayPosition = (details.localPosition.dx /
                      constraints.maxWidth)
                  .clamp(0.0, 1.0);
            });
          },
          child: Stack(
            children: [
              // Before (full width)
              Center(
                child: Transform.scale(
                  scale: _zoom,
                  child: widget.before,
                ),
              ),
              // After (clipped from left)
              ClipRect(
                clipper: _OverlayClipper(_overlayPosition),
                child: Center(
                  child: Transform.scale(
                    scale: _zoom,
                    child: widget.after,
                  ),
                ),
              ),
              // Divider line
              Positioned(
                left: constraints.maxWidth * _overlayPosition - 1,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 2,
                  color: EdenColors.info,
                ),
              ),
              // Divider handle
              Positioned(
                left: constraints.maxWidth * _overlayPosition - 14,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: EdenColors.info,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.drag_handle,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              // Labels
              Positioned(
                left: EdenSpacing.space2,
                top: EdenSpacing.space2,
                child: _OverlayLabel(text: widget.beforeLabel),
              ),
              Positioned(
                right: EdenSpacing.space2,
                top: EdenSpacing.space2,
                child: _OverlayLabel(text: widget.afterLabel),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOnionSkin() {
    return Stack(
      children: [
        Center(
          child: Transform.scale(
            scale: _zoom,
            child: Opacity(
              opacity: 1.0 - _onionSkinOpacity,
              child: widget.before,
            ),
          ),
        ),
        Center(
          child: Transform.scale(
            scale: _zoom,
            child: Opacity(
              opacity: _onionSkinOpacity,
              child: widget.after,
            ),
          ),
        ),
      ],
    );
  }
}

class _OverlayClipper extends CustomClipper<Rect> {
  _OverlayClipper(this.position);

  final double position;

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(size.width * position, 0,
        size.width * (1 - position), size.height);
  }

  @override
  bool shouldReclip(covariant _OverlayClipper oldClipper) {
    return oldClipper.position != position;
  }
}

class _OverlayLabel extends StatelessWidget {
  const _OverlayLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space2,
        vertical: EdenSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: EdenRadii.borderRadiusSm,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.activeBg,
    required this.inactiveColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color activeBg;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? activeBg : Colors.transparent,
      borderRadius: EdenRadii.borderRadiusSm,
      child: InkWell(
        onTap: onTap,
        borderRadius: EdenRadii.borderRadiusSm,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: EdenSpacing.space2,
            vertical: EdenSpacing.space1,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isActive ? activeColor : inactiveColor,
              ),
              const SizedBox(width: EdenSpacing.space1),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 28,
        height: 28,
        child: Material(
          color: Colors.transparent,
          borderRadius: EdenRadii.borderRadiusSm,
          child: InkWell(
            onTap: onTap,
            borderRadius: EdenRadii.borderRadiusSm,
            child: Center(
              child: Icon(icon, size: 16, color: color),
            ),
          ),
        ),
      ),
    );
  }
}
