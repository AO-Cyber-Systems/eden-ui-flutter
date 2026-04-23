import 'package:flutter/material.dart';
import '../../tokens/colors.dart';
import '../../tokens/radii.dart';
import '../eden_conversation_thread.dart';

class CompactDot extends StatelessWidget {
  const CompactDot({super.key, required this.eventType, required this.isDark});

  final EdenConversationEventType eventType;
  final bool isDark;

  IconData _icon() {
    switch (eventType) {
      case EdenConversationEventType.labelChange:
        return Icons.label_outline;
      case EdenConversationEventType.assignmentChange:
        return Icons.person_outline;
      case EdenConversationEventType.statusChange:
        return Icons.info_outline;
      case EdenConversationEventType.commitRef:
        return Icons.commit;
      case EdenConversationEventType.crossRef:
        return Icons.link;
      case EdenConversationEventType.merge:
        return Icons.merge;
      case EdenConversationEventType.comment:
      case EdenConversationEventType.reviewSummary:
        return Icons.circle;
    }
  }

  Color _color() {
    switch (eventType) {
      case EdenConversationEventType.statusChange:
        return EdenColors.purple[500]!;
      case EdenConversationEventType.merge:
        return EdenColors.purple[500]!;
      case EdenConversationEventType.commitRef:
        return EdenColors.blue[500]!;
      case EdenConversationEventType.labelChange:
        return EdenColors.neutral[500]!;
      case EdenConversationEventType.assignmentChange:
        return EdenColors.neutral[500]!;
      case EdenConversationEventType.crossRef:
        return EdenColors.blue[500]!;
      default:
        return EdenColors.neutral[500]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(_icon(), size: 16, color: color),
    );
  }
}

class LabelPill extends StatelessWidget {
  const LabelPill({super.key, required this.label, required this.isDark});

  final dynamic label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final map = label as Map<String, dynamic>;
    final name = map['name'] as String? ?? '';
    final colorHex = map['color'] as String? ?? '';
    final color = _parseColor(colorHex);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: EdenRadii.borderRadiusFull,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDark ? color : _darken(color),
        ),
      ),
    );
  }

  static Color _parseColor(String hex) {
    if (hex.isEmpty) return EdenColors.neutral[500]!;
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    }
    return EdenColors.neutral[500]!;
  }

  static Color _darken(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness * 0.7).clamp(0.0, 1.0)).toColor();
  }
}
