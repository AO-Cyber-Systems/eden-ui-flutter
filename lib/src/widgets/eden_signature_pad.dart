import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// A single point with pressure data in a signature stroke.
class EdenSignaturePoint {
  const EdenSignaturePoint(this.x, this.y, [this.pressure = 1.0]);

  final double x;
  final double y;
  final double pressure;

  Offset toOffset() => Offset(x, y);
}

/// A continuous pen stroke comprising an ordered list of points.
class EdenSignatureStroke {
  const EdenSignatureStroke({
    required this.points,
    this.color = const Color(0xFF18181B),
    this.width = 2.5,
  });

  final List<EdenSignaturePoint> points;
  final Color color;
  final double width;

  EdenSignatureStroke copyWith({
    List<EdenSignaturePoint>? points,
    Color? color,
    double? width,
  }) {
    return EdenSignatureStroke(
      points: points ?? this.points,
      color: color ?? this.color,
      width: width ?? this.width,
    );
  }
}

/// A signature capture pad for e-signatures.
///
/// Supports touch and pen input with undo/redo, configurable pen color and
/// width, and a read-only replay mode. The pad notifies consumers of stroke
/// changes via [onSignatureChanged] so they can serialise / rasterise the
/// signature externally.
class EdenSignaturePad extends StatefulWidget {
  const EdenSignaturePad({
    super.key,
    this.initialStrokes = const [],
    this.penColor,
    this.penWidth = 2.5,
    this.showControls = true,
    this.readOnly = false,
    this.height = 200,
    this.placeholderText = 'Sign here',
    this.backgroundColor,
    this.borderColor,
    this.onSignatureChanged,
  });

  /// Strokes to display initially (e.g. for replay / read-only mode).
  final List<EdenSignatureStroke> initialStrokes;

  /// Default pen colour. When null the widget uses the current theme's
  /// foreground colour.
  final Color? penColor;

  /// Default pen stroke width in logical pixels.
  final double penWidth;

  /// Whether to show the clear / undo / redo toolbar.
  final bool showControls;

  /// When true the canvas is non-interactive and simply renders the strokes.
  final bool readOnly;

  /// Explicit height for the drawing area.
  final double height;

  /// Placeholder text shown when the canvas is empty.
  final String placeholderText;

  /// Background colour override. Falls back to surface colour from the theme.
  final Color? backgroundColor;

  /// Border colour override. Falls back to a neutral token.
  final Color? borderColor;

  /// Called every time the stroke list changes (draw, undo, redo, clear).
  final ValueChanged<List<EdenSignatureStroke>>? onSignatureChanged;

  @override
  State<EdenSignaturePad> createState() => _EdenSignaturePadState();
}

class _EdenSignaturePadState extends State<EdenSignaturePad> {
  late List<EdenSignatureStroke> _strokes;
  List<EdenSignatureStroke> _redoStack = [];
  EdenSignatureStroke? _currentStroke;

  late Color _penColor;
  late double _penWidth;

  @override
  void initState() {
    super.initState();
    _strokes = List<EdenSignatureStroke>.of(widget.initialStrokes);
    _penColor = widget.penColor ?? const Color(0xFF18181B);
    _penWidth = widget.penWidth;
  }

  @override
  void didUpdateWidget(EdenSignaturePad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.penColor != null && widget.penColor != oldWidget.penColor) {
      _penColor = widget.penColor!;
    }
    if (widget.penWidth != oldWidget.penWidth) {
      _penWidth = widget.penWidth;
    }
    // If the consumer replaces initialStrokes (e.g. loading a saved sig) and
    // the pad is read-only, sync.
    if (widget.readOnly && widget.initialStrokes != oldWidget.initialStrokes) {
      _strokes = List<EdenSignatureStroke>.of(widget.initialStrokes);
    }
  }

  // ---------------------------------------------------------------------------
  // Signature state
  // ---------------------------------------------------------------------------

  bool get _isEmpty => _strokes.isEmpty && _currentStroke == null;
  bool get _canUndo => _strokes.isNotEmpty;
  bool get _canRedo => _redoStack.isNotEmpty;

  void _notifyChanged() {
    widget.onSignatureChanged?.call(List.unmodifiable(_strokes));
  }

  void _clear() {
    setState(() {
      _strokes = [];
      _redoStack = [];
      _currentStroke = null;
    });
    _notifyChanged();
  }

  void _undo() {
    if (!_canUndo) return;
    setState(() {
      _redoStack = [..._redoStack, _strokes.last];
      _strokes = _strokes.sublist(0, _strokes.length - 1);
    });
    _notifyChanged();
  }

  void _redo() {
    if (!_canRedo) return;
    setState(() {
      _strokes = [..._strokes, _redoStack.last];
      _redoStack = _redoStack.sublist(0, _redoStack.length - 1);
    });
    _notifyChanged();
  }

  // ---------------------------------------------------------------------------
  // Drawing handlers
  // ---------------------------------------------------------------------------

  void _onPanStart(DragStartDetails details) {
    final point = EdenSignaturePoint(
      details.localPosition.dx,
      details.localPosition.dy,
    );
    setState(() {
      _currentStroke = EdenSignatureStroke(
        points: [point],
        color: _penColor,
        width: _penWidth,
      );
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_currentStroke == null) return;
    final point = EdenSignaturePoint(
      details.localPosition.dx,
      details.localPosition.dy,
    );
    setState(() {
      _currentStroke = _currentStroke!.copyWith(
        points: [..._currentStroke!.points, point],
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentStroke == null) return;
    setState(() {
      _strokes = [..._strokes, _currentStroke!];
      _currentStroke = null;
      _redoStack = []; // new stroke clears redo history
    });
    _notifyChanged();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = widget.backgroundColor ??
        (isDark ? EdenColors.neutral[900]! : Colors.white);
    final border = widget.borderColor ??
        (isDark ? EdenColors.neutral[700]! : EdenColors.neutral[300]!);
    final mutedText =
        isDark ? EdenColors.neutral[500]! : EdenColors.neutral[400]!;

    // Resolve pen color for dark mode when using the default.
    if (widget.penColor == null) {
      _penColor = isDark ? Colors.white : const Color(0xFF18181B);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: widget.showControls
                ? const BorderRadius.only(
                    topLeft: Radius.circular(EdenRadii.md),
                    topRight: Radius.circular(EdenRadii.md),
                  )
                : EdenRadii.borderRadiusMd,
            border: Border.all(color: border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Sign-here line + placeholder
              if (_isEmpty)
                _buildPlaceholder(theme, mutedText, border),

              // Canvas
              Positioned.fill(
                child: widget.readOnly
                    ? CustomPaint(
                        painter: _SignaturePainter(
                          strokes: _strokes,
                          currentStroke: null,
                        ),
                      )
                    : GestureDetector(
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        child: CustomPaint(
                          painter: _SignaturePainter(
                            strokes: _strokes,
                            currentStroke: _currentStroke,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
        if (widget.showControls && !widget.readOnly)
          _buildControls(theme, isDark, bgColor, border),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Placeholder
  // ---------------------------------------------------------------------------

  Widget _buildPlaceholder(ThemeData theme, Color mutedText, Color lineColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: EdenSpacing.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.placeholderText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: mutedText,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: EdenSpacing.space3),
            Container(
              height: 1,
              color: lineColor,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Controls toolbar
  // ---------------------------------------------------------------------------

  Widget _buildControls(
    ThemeData theme,
    bool isDark,
    Color bgColor,
    Color border,
  ) {
    final iconColor =
        isDark ? EdenColors.neutral[300]! : EdenColors.neutral[600]!;
    final disabledColor =
        isDark ? EdenColors.neutral[600]! : EdenColors.neutral[300]!;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space3,
        vertical: EdenSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          left: BorderSide(color: border),
          right: BorderSide(color: border),
          bottom: BorderSide(color: border),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(EdenRadii.md),
          bottomRight: Radius.circular(EdenRadii.md),
        ),
      ),
      child: Row(
        children: [
          _PadIconButton(
            icon: Icons.undo_rounded,
            tooltip: 'Undo',
            color: _canUndo ? iconColor : disabledColor,
            onPressed: _canUndo ? _undo : null,
          ),
          const SizedBox(width: EdenSpacing.space1),
          _PadIconButton(
            icon: Icons.redo_rounded,
            tooltip: 'Redo',
            color: _canRedo ? iconColor : disabledColor,
            onPressed: _canRedo ? _redo : null,
          ),
          const Spacer(),
          // Pen colour swatches
          _buildColorSwatch(Colors.black, isDark),
          const SizedBox(width: EdenSpacing.space1),
          _buildColorSwatch(EdenColors.blue, isDark),
          const SizedBox(width: EdenSpacing.space1),
          _buildColorSwatch(EdenColors.red, isDark),
          const Spacer(),
          _PadIconButton(
            icon: Icons.delete_outline_rounded,
            tooltip: 'Clear',
            color: _canUndo ? EdenColors.error : disabledColor,
            onPressed: _canUndo ? _clear : null,
          ),
        ],
      ),
    );
  }

  Widget _buildColorSwatch(Color color, bool isDark) {
    final isSelected = _penColor.toARGB32() == color.toARGB32();
    final checkColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
            ? Colors.white
            : Colors.black;

    return GestureDetector(
      onTap: () => setState(() => _penColor = color),
      child: Tooltip(
        message: 'Pen colour',
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? (isDark
                      ? EdenColors.neutral[300]!
                      : EdenColors.neutral[600]!)
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: isSelected
              ? Icon(Icons.check, size: 12, color: checkColor)
              : null,
        ),
      ),
    );
  }
}

// =============================================================================
// Painter
// =============================================================================

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter({
    required this.strokes,
    required this.currentStroke,
  });

  final List<EdenSignatureStroke> strokes;
  final EdenSignatureStroke? currentStroke;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }
    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!);
    }
  }

  void _drawStroke(Canvas canvas, EdenSignatureStroke stroke) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (stroke.points.length == 1) {
      // Single dot
      final p = stroke.points.first.toOffset();
      canvas.drawCircle(p, stroke.width / 2, paint..style = PaintingStyle.fill);
      return;
    }

    final path = Path();
    path.moveTo(stroke.points.first.x, stroke.points.first.y);

    // Use quadratic bezier curves for smooth lines
    for (var i = 1; i < stroke.points.length; i++) {
      final prev = stroke.points[i - 1];
      final curr = stroke.points[i];
      final midX = (prev.x + curr.x) / 2;
      final midY = (prev.y + curr.y) / 2;
      path.quadraticBezierTo(prev.x, prev.y, midX, midY);
    }

    // Draw to the last point
    final last = stroke.points.last;
    path.lineTo(last.x, last.y);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SignaturePainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.currentStroke != currentStroke;
  }
}

// =============================================================================
// Small icon button for the controls bar
// =============================================================================

class _PadIconButton extends StatelessWidget {
  const _PadIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
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
    );
  }
}
