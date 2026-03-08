import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'diagram_data.dart';

/// Parses a hex color string like "#3B82F6" or "3B82F6" to a Color.
Color _hexToColor(String hex) {
  hex = hex.replaceFirst('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  return Color(int.parse(hex, radix: 16));
}

/// Custom painter that renders all nodes and edges on the canvas.
class EdenDiagramPainter extends CustomPainter {
  EdenDiagramPainter({
    required this.data,
    required this.theme,
    this.selectedNodeId,
    this.hoveredNodeId,
    this.dragEdgeStart,
    this.dragEdgeEnd,
    this.gridEnabled = true,
  });

  final EdenDiagramData data;
  final ThemeData theme;
  final String? selectedNodeId;
  final String? hoveredNodeId;
  final Offset? dragEdgeStart;
  final Offset? dragEdgeEnd;
  final bool gridEnabled;

  @override
  void paint(Canvas canvas, Size size) {
    if (gridEnabled) _drawGrid(canvas, size);
    for (final edge in data.edges) {
      _drawEdge(canvas, edge);
    }
    if (dragEdgeStart != null && dragEdgeEnd != null) {
      _drawDragEdge(canvas);
    }
    for (final node in data.nodes) {
      _drawNode(canvas, node);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = theme.colorScheme.outlineVariant.withValues(alpha: 0.15)
      ..strokeWidth = 1;
    const step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawNode(Canvas canvas, EdenDiagramNode node) {
    final isSelected = node.id == selectedNodeId;
    final isHovered = node.id == hoveredNodeId;
    final isDark = theme.brightness == Brightness.dark;

    final fillColor = node.color != null
        ? _hexToColor(node.color!)
        : isDark
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.surface;

    final borderColorResolved = node.borderColor != null
        ? _hexToColor(node.borderColor!)
        : isSelected
            ? theme.colorScheme.primary
            : isHovered
                ? theme.colorScheme.primary.withValues(alpha: 0.6)
                : theme.colorScheme.outlineVariant;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColorResolved
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.5 : isHovered ? 2.0 : 1.5;

    final rect = Rect.fromLTWH(node.x, node.y, node.width, node.height);

    // Draw shadow
    if (isSelected || isHovered) {
      final shadowPaint = Paint()
        ..color = theme.colorScheme.primary.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawRRect(RRect.fromRectAndRadius(rect.inflate(2), const Radius.circular(8)), shadowPaint);
    }

    // Draw shape
    switch (node.shape) {
      case EdenNodeShape.rectangle:
        canvas.drawRect(rect, fillPaint);
        canvas.drawRect(rect, borderPaint);
        break;
      case EdenNodeShape.roundedRect:
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
        canvas.drawRRect(rrect, fillPaint);
        canvas.drawRRect(rrect, borderPaint);
        break;
      case EdenNodeShape.circle:
        final radius = math.min(node.width, node.height) / 2;
        canvas.drawCircle(node.center, radius, fillPaint);
        canvas.drawCircle(node.center, radius, borderPaint);
        break;
      case EdenNodeShape.pill:
        final rrect = RRect.fromRectAndRadius(rect, Radius.circular(node.height / 2));
        canvas.drawRRect(rrect, fillPaint);
        canvas.drawRRect(rrect, borderPaint);
        break;
      case EdenNodeShape.diamond:
        final path = Path()
          ..moveTo(node.center.dx, node.y)
          ..lineTo(node.x + node.width, node.center.dy)
          ..lineTo(node.center.dx, node.y + node.height)
          ..lineTo(node.x, node.center.dy)
          ..close();
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, borderPaint);
        break;
      case EdenNodeShape.cylinder:
        _drawCylinder(canvas, rect, fillPaint, borderPaint);
        break;
      case EdenNodeShape.hexagon:
        _drawHexagon(canvas, rect, fillPaint, borderPaint);
        break;
      case EdenNodeShape.parallelogram:
        _drawParallelogram(canvas, rect, fillPaint, borderPaint);
        break;
    }

    // Draw label
    final textColor = node.textColor != null
        ? _hexToColor(node.textColor!)
        : theme.colorScheme.onSurface;

    if (node.label.isNotEmpty) {
      final textSpan = TextSpan(
        text: node.label,
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      );
      final tp = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: node.width - 16);

      final labelY = node.sublabel != null
          ? node.center.dy - tp.height - 1
          : node.center.dy - tp.height / 2;
      tp.paint(canvas, Offset(node.center.dx - tp.width / 2, labelY));
    }

    if (node.sublabel != null && node.sublabel!.isNotEmpty) {
      final subSpan = TextSpan(
        text: node.sublabel!,
        style: TextStyle(
          color: textColor.withValues(alpha: 0.6),
          fontSize: 10,
          fontWeight: FontWeight.w400,
        ),
      );
      final subTp = TextPainter(
        text: subSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: node.width - 16);
      subTp.paint(canvas, Offset(node.center.dx - subTp.width / 2, node.center.dy + 2));
    }

    // Draw port dots when selected or hovered
    if (isSelected || isHovered) {
      final portPaint = Paint()..color = theme.colorScheme.primary;
      for (final side in EdenPortSide.values) {
        canvas.drawCircle(node.portOffset(side), 4, portPaint);
      }
    }
  }

  void _drawCylinder(Canvas canvas, Rect rect, Paint fill, Paint border) {
    const ellipseH = 10.0;
    final bodyRect = Rect.fromLTWH(rect.left, rect.top + ellipseH / 2, rect.width, rect.height - ellipseH);

    // Body
    canvas.drawRect(bodyRect, fill);
    // Bottom ellipse
    canvas.drawOval(Rect.fromLTWH(rect.left, rect.bottom - ellipseH, rect.width, ellipseH), fill);
    canvas.drawOval(Rect.fromLTWH(rect.left, rect.bottom - ellipseH, rect.width, ellipseH), border);
    // Side lines
    canvas.drawLine(Offset(rect.left, rect.top + ellipseH / 2), Offset(rect.left, rect.bottom - ellipseH / 2), border);
    canvas.drawLine(Offset(rect.right, rect.top + ellipseH / 2), Offset(rect.right, rect.bottom - ellipseH / 2), border);
    // Top ellipse
    canvas.drawOval(Rect.fromLTWH(rect.left, rect.top, rect.width, ellipseH), fill);
    canvas.drawOval(Rect.fromLTWH(rect.left, rect.top, rect.width, ellipseH), border);
  }

  void _drawHexagon(Canvas canvas, Rect rect, Paint fill, Paint border) {
    final inset = rect.width * 0.22;
    final path = Path()
      ..moveTo(rect.left + inset, rect.top)
      ..lineTo(rect.right - inset, rect.top)
      ..lineTo(rect.right, rect.center.dy)
      ..lineTo(rect.right - inset, rect.bottom)
      ..lineTo(rect.left + inset, rect.bottom)
      ..lineTo(rect.left, rect.center.dy)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, border);
  }

  void _drawParallelogram(Canvas canvas, Rect rect, Paint fill, Paint border) {
    final skew = rect.width * 0.18;
    final path = Path()
      ..moveTo(rect.left + skew, rect.top)
      ..lineTo(rect.right, rect.top)
      ..lineTo(rect.right - skew, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, border);
  }

  void _drawEdge(Canvas canvas, EdenDiagramEdge edge) {
    final sourceNode = data.nodeById(edge.sourceId);
    final targetNode = data.nodeById(edge.targetId);
    if (sourceNode == null || targetNode == null) return;

    final start = sourceNode.portOffset(edge.sourcePort);
    final end = targetNode.portOffset(edge.targetPort);

    final edgeColor = edge.color != null
        ? _hexToColor(edge.color!)
        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6);

    final paint = Paint()
      ..color = edgeColor
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    if (edge.style == EdenEdgeStyle.dashed) {
      _drawDashedLine(canvas, start, end, paint, 8, 4);
    } else if (edge.style == EdenEdgeStyle.dotted) {
      _drawDashedLine(canvas, start, end, paint, 3, 3);
    } else {
      // Draw cubic bezier for smooth routing
      final path = _buildEdgePath(start, end, edge.sourcePort, edge.targetPort);
      canvas.drawPath(path, paint);
    }

    // Arrowhead
    if (edge.arrowHead != EdenArrowHead.none) {
      _drawArrowHead(canvas, start, end, edge.targetPort, edgeColor, edge.arrowHead);
    }

    // Edge label
    if (edge.label != null && edge.label!.isNotEmpty) {
      final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
      final bgPaint = Paint()..color = theme.colorScheme.surface;
      final textSpan = TextSpan(
        text: edge.label!,
        style: TextStyle(color: edgeColor, fontSize: 10, fontWeight: FontWeight.w500),
      );
      final tp = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      final labelRect = Rect.fromCenter(center: mid, width: tp.width + 8, height: tp.height + 4);
      canvas.drawRRect(RRect.fromRectAndRadius(labelRect, const Radius.circular(4)), bgPaint);
      tp.paint(canvas, Offset(mid.dx - tp.width / 2, mid.dy - tp.height / 2));
    }
  }

  Path _buildEdgePath(Offset start, Offset end, EdenPortSide sourcePort, EdenPortSide targetPort) {
    final dx = (end.dx - start.dx).abs() * 0.5;
    final dy = (end.dy - start.dy).abs() * 0.5;

    Offset cp1, cp2;
    switch (sourcePort) {
      case EdenPortSide.right:
        cp1 = Offset(start.dx + dx.clamp(40, 120), start.dy);
        break;
      case EdenPortSide.left:
        cp1 = Offset(start.dx - dx.clamp(40, 120), start.dy);
        break;
      case EdenPortSide.bottom:
        cp1 = Offset(start.dx, start.dy + dy.clamp(40, 120));
        break;
      case EdenPortSide.top:
        cp1 = Offset(start.dx, start.dy - dy.clamp(40, 120));
        break;
    }
    switch (targetPort) {
      case EdenPortSide.left:
        cp2 = Offset(end.dx - dx.clamp(40, 120), end.dy);
        break;
      case EdenPortSide.right:
        cp2 = Offset(end.dx + dx.clamp(40, 120), end.dy);
        break;
      case EdenPortSide.top:
        cp2 = Offset(end.dx, end.dy - dy.clamp(40, 120));
        break;
      case EdenPortSide.bottom:
        cp2 = Offset(end.dx, end.dy + dy.clamp(40, 120));
        break;
    }

    return Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint, double dashLen, double gapLen) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    final steps = dist / (dashLen + gapLen);
    final ux = dx / dist;
    final uy = dy / dist;

    for (int i = 0; i < steps; i++) {
      final s = Offset(start.dx + ux * i * (dashLen + gapLen), start.dy + uy * i * (dashLen + gapLen));
      final e = Offset(s.dx + ux * dashLen, s.dy + uy * dashLen);
      canvas.drawLine(s, e, paint);
    }
  }

  void _drawArrowHead(Canvas canvas, Offset start, Offset end, EdenPortSide targetPort, Color color, EdenArrowHead type) {
    const size = 10.0;
    double angle;
    switch (targetPort) {
      case EdenPortSide.left:
        angle = math.pi;
        break;
      case EdenPortSide.right:
        angle = 0;
        break;
      case EdenPortSide.top:
        angle = -math.pi / 2;
        break;
      case EdenPortSide.bottom:
        angle = math.pi / 2;
        break;
    }

    canvas.save();
    canvas.translate(end.dx, end.dy);
    canvas.rotate(angle);

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(-size, -size / 2)
      ..lineTo(-size, size / 2)
      ..close();

    if (type == EdenArrowHead.filledArrow || type == EdenArrowHead.arrow) {
      final paint = Paint()
        ..color = color
        ..style = type == EdenArrowHead.filledArrow ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawPath(path, paint);
    } else if (type == EdenArrowHead.diamond) {
      final dPath = Path()
        ..moveTo(0, 0)
        ..lineTo(-size / 2, -size / 3)
        ..lineTo(-size, 0)
        ..lineTo(-size / 2, size / 3)
        ..close();
      canvas.drawPath(dPath, Paint()..color = color..style = PaintingStyle.fill);
    } else if (type == EdenArrowHead.circle) {
      canvas.drawCircle(Offset(-size / 2, 0), size / 3, Paint()..color = color..style = PaintingStyle.fill);
    }

    canvas.restore();
  }

  void _drawDragEdge(Canvas canvas) {
    final paint = Paint()
      ..color = theme.colorScheme.primary.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(dragEdgeStart!, dragEdgeEnd!, paint);
  }

  @override
  bool shouldRepaint(covariant EdenDiagramPainter oldDelegate) => true;
}
