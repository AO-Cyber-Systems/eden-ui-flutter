import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Priority level for kanban cards.
enum EdenKanbanPriority { high, medium, low }

/// Color theme for kanban columns.
enum EdenKanbanColumnColor { primary, success, warning, danger, neutral }

/// A tag on a kanban card.
class EdenKanbanTag {
  const EdenKanbanTag({required this.label, this.color});
  final String label;
  final Color? color;
}

/// Data transferred during a kanban card drag operation.
class _KanbanDragData {
  const _KanbanDragData({
    required this.cardId,
    required this.columnId,
    required this.cardIndex,
    required this.card,
  });

  final String cardId;
  final String columnId;
  final int cardIndex;
  final EdenKanbanCard card;
}

/// A single card within a kanban column.
class EdenKanbanCard extends StatelessWidget {
  const EdenKanbanCard({
    super.key,
    this.id,
    required this.title,
    this.description,
    this.priority,
    this.dueDate,
    this.assigneeInitials = const [],
    this.tags = const [],
    this.onTap,
  });

  /// Unique identifier for this card. Required for drag-and-drop operations.
  final String? id;
  final String title;
  final String? description;
  final EdenKanbanPriority? priority;
  final String? dueDate;
  final List<String> assigneeInitials;
  final List<EdenKanbanTag> tags;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _buildCardContent(context);
  }

  /// Builds the visual card content. Extracted so it can be reused for drag
  /// feedback without wrapping in GestureDetector.
  Widget _buildCardContent(BuildContext context, {double opacity = 1.0}) {
    final theme = Theme.of(context);

    return Opacity(
      opacity: opacity,
      child: Semantics(
        button: onTap != null,
        label: title,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(EdenSpacing.space3),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: EdenRadii.borderRadiusLg,
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (priority != null) ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _priorityColor(),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(title, style: theme.textTheme.titleSmall),
                  ),
                ],
              ),
              if (description != null) ...[
                const SizedBox(height: 6),
                Text(
                  description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: tags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (tag.color ?? EdenColors.info).withValues(alpha: 0.1),
                      borderRadius: EdenRadii.borderRadiusFull,
                    ),
                    child: Text(
                      tag.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: tag.color ?? EdenColors.info,
                      ),
                    ),
                  )).toList(),
                ),
              ],
              if (assigneeInitials.isNotEmpty || dueDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (assigneeInitials.isNotEmpty)
                      SizedBox(
                        height: 24,
                        child: Row(
                          children: [
                            for (int i = 0; i < assigneeInitials.length && i < 3; i++)
                              Transform.translate(
                                offset: Offset(-6.0 * i, 0),
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                                  child: Text(
                                    assigneeInitials[i],
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: theme.colorScheme.primary),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    if (dueDate != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today, size: 12, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            dueDate!,
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      ),
    );
  }

  /// Builds the drag feedback widget — a semi-transparent, slightly rotated
  /// copy of the card.
  Widget buildDragFeedback(BuildContext context, double width) {
    return Transform.rotate(
      angle: 0.035, // ~2 degrees
      child: SizedBox(
        width: width,
        child: Material(
          color: Colors.transparent,
          child: _buildCardContent(context, opacity: 0.85),
        ),
      ),
    );
  }

  Color _priorityColor() {
    switch (priority!) {
      case EdenKanbanPriority.high:
        return EdenColors.error;
      case EdenKanbanPriority.medium:
        return EdenColors.warning;
      case EdenKanbanPriority.low:
        return EdenColors.success;
    }
  }
}

/// A dashed-border placeholder shown where a card will be dropped.
class _DropPlaceholder extends StatelessWidget {
  const _DropPlaceholder();

  static const double height = 60;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: EdenRadii.borderRadiusLg,
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.4),
          style: BorderStyle.solid,
        ),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: EdenRadii.borderRadiusLg,
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
      ),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: theme.colorScheme.primary.withValues(alpha: 0.4),
          borderRadius: 8,
          dashWidth: 6,
          dashSpace: 4,
        ),
      ),
    );
  }
}

/// Paints a dashed rounded-rectangle border.
class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    this.borderRadius = 8,
    this.dashWidth = 6,
    this.dashSpace = 4,
  });

  final Color color;
  final double borderRadius;
  final double dashWidth;
  final double dashSpace;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(borderRadius),
      ));

    final metrics = path.computeMetrics().first;
    final totalLength = metrics.length;
    double distance = 0;

    while (distance < totalLength) {
      final end = math.min(distance + dashWidth, totalLength);
      canvas.drawPath(
        metrics.extractPath(distance, end),
        paint,
      );
      distance = end + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color;
}

/// A column in a kanban board.
class EdenKanbanColumn extends StatelessWidget {
  const EdenKanbanColumn({
    super.key,
    this.id,
    required this.title,
    this.count,
    this.color = EdenKanbanColumnColor.neutral,
    this.children = const [],
    this.width = 280,
    this.onAddCard,
  });

  /// Unique identifier for this column. Required for drag-and-drop operations.
  final String? id;
  final String title;
  final int? count;
  final EdenKanbanColumnColor color;
  final List<Widget> children;
  final double width;

  /// Called when the "+" button at the bottom of the column is tapped.
  final VoidCallback? onAddCard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = _resolveColor(theme);

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: isDark ? EdenColors.neutral[850] : EdenColors.neutral[50],
        borderRadius: EdenRadii.borderRadiusLg,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Color bar
          Container(height: 4, color: accentColor),
          // Header
          Padding(
            padding: const EdgeInsets.all(EdenSpacing.space3),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: accentColor),
                ),
                const SizedBox(width: 8),
                Text(title, style: theme.textTheme.labelLarge),
                if (count != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
                      borderRadius: EdenRadii.borderRadiusFull,
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Cards
          Padding(
            padding: const EdgeInsets.fromLTRB(EdenSpacing.space3, 0, EdenSpacing.space3, EdenSpacing.space3),
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  children[i],
                ],
                // Add card button
                if (onAddCard != null) ...[
                  if (children.isNotEmpty) const SizedBox(height: 8),
                  _AddCardButton(onTap: onAddCard!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _resolveColor(ThemeData theme) {
    switch (color) {
      case EdenKanbanColumnColor.primary:
        return theme.colorScheme.primary;
      case EdenKanbanColumnColor.success:
        return EdenColors.success;
      case EdenKanbanColumnColor.warning:
        return EdenColors.warning;
      case EdenKanbanColumnColor.danger:
        return EdenColors.error;
      case EdenKanbanColumnColor.neutral:
        return EdenColors.neutral[400]!;
    }
  }
}

/// "+" button for adding a new card at the bottom of a column.
class _AddCardButton extends StatelessWidget {
  const _AddCardButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'Add card',
      child: InkWell(
        onTap: onTap,
        borderRadius: EdenRadii.borderRadiusLg,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: EdenSpacing.space2),
          decoration: BoxDecoration(
            borderRadius: EdenRadii.borderRadiusLg,
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                'Add card',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal scrollable kanban board with drag-and-drop support.
///
/// When [onCardMoved] and [onCardReordered] are provided alongside cards and
/// columns that have [EdenKanbanCard.id] / [EdenKanbanColumn.id] set, cards
/// become draggable between and within columns.
///
/// Without those callbacks the board behaves identically to the original
/// static implementation — full backward compatibility is maintained.
class EdenKanbanBoard extends StatefulWidget {
  const EdenKanbanBoard({
    super.key,
    required this.children,
    this.onCardMoved,
    this.onCardReordered,
  });

  final List<Widget> children;

  /// Called when a card is dragged into a different column.
  final void Function(
    String cardId,
    String fromColumnId,
    String toColumnId,
    int newIndex,
  )? onCardMoved;

  /// Called when a card is reordered within the same column.
  final void Function(
    String cardId,
    String columnId,
    int oldIndex,
    int newIndex,
  )? onCardReordered;

  @override
  State<EdenKanbanBoard> createState() => _EdenKanbanBoardState();
}

class _EdenKanbanBoardState extends State<EdenKanbanBoard> {
  /// The column id currently being hovered over during a drag.
  String? _hoveredColumnId;

  /// The insertion index within the hovered column.
  int? _hoverInsertIndex;

  /// Whether drag-and-drop is enabled (requires callbacks).
  bool get _dragEnabled =>
      widget.onCardMoved != null || widget.onCardReordered != null;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: EdenSpacing.space4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < widget.children.length; i++) ...[
            if (i > 0) const SizedBox(width: EdenSpacing.space4),
            _dragEnabled
                ? _buildDraggableColumn(widget.children[i])
                : widget.children[i],
          ],
        ],
      ),
    );
  }

  /// Wraps a column in a [DragTarget] so it can accept card drops, and wraps
  /// each card inside the column in a [LongPressDraggable].
  Widget _buildDraggableColumn(Widget columnWidget) {
    if (columnWidget is! EdenKanbanColumn) return columnWidget;
    final column = columnWidget;
    final columnId = column.id;
    if (columnId == null) return columnWidget;

    final isHovered = _hoveredColumnId == columnId;

    return DragTarget<_KanbanDragData>(
      onWillAcceptWithDetails: (details) {
        if (details.data.card.id == null) return false;
        setState(() {
          _hoveredColumnId = columnId;
          _hoverInsertIndex = column.children.length;
        });
        return true;
      },
      onLeave: (_) {
        if (_hoveredColumnId == columnId) {
          setState(() {
            _hoveredColumnId = null;
            _hoverInsertIndex = null;
          });
        }
      },
      onAcceptWithDetails: (details) {
        final data = details.data;
        final insertIndex = _hoverInsertIndex ?? column.children.length;

        setState(() {
          _hoveredColumnId = null;
          _hoverInsertIndex = null;
        });

        if (data.columnId == columnId) {
          // Reorder within the same column.
          if (data.cardIndex != insertIndex &&
              data.cardIndex != insertIndex - 1) {
            widget.onCardReordered?.call(
              data.cardId,
              columnId,
              data.cardIndex,
              insertIndex > data.cardIndex ? insertIndex - 1 : insertIndex,
            );
          }
        } else {
          // Move between columns.
          widget.onCardMoved?.call(
            data.cardId,
            data.columnId,
            columnId,
            insertIndex,
          );
        }
      },
      builder: (context, candidateData, rejectedData) {
        return _buildColumnWithDraggableCards(
          column,
          columnId,
          isHovered: isHovered,
        );
      },
    );
  }

  /// Rebuilds a column replacing its children with draggable cards and
  /// inserting a drop placeholder at the correct position when hovered.
  Widget _buildColumnWithDraggableCards(
    EdenKanbanColumn column,
    String columnId, {
    required bool isHovered,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = column._resolveColor(theme);

    // Build the card list with draggable wrappers + placeholder.
    final cardWidgets = <Widget>[];
    final insertIdx = _hoverInsertIndex;

    for (int i = 0; i < column.children.length; i++) {
      // Insert placeholder before this index when hovered.
      if (isHovered && insertIdx == i) {
        cardWidgets.add(const _DropPlaceholder());
      }

      final child = column.children[i];
      if (child is EdenKanbanCard && child.id != null) {
        cardWidgets.add(
          _DraggableCard(
            card: child,
            columnId: columnId,
            cardIndex: i,
            columnWidth: column.width,
            onHoverIndex: (index) {
              if (_hoveredColumnId == columnId) {
                setState(() => _hoverInsertIndex = index);
              }
            },
          ),
        );
      } else {
        cardWidgets.add(child);
      }
    }

    // Placeholder at the end of the column.
    if (isHovered && (insertIdx == null || insertIdx >= column.children.length)) {
      cardWidgets.add(const _DropPlaceholder());
    }

    // Reconstruct the column visuals (avoids nesting a second EdenKanbanColumn).
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: column.width,
      decoration: BoxDecoration(
        color: isDark ? EdenColors.neutral[850] : EdenColors.neutral[50],
        borderRadius: EdenRadii.borderRadiusLg,
        border: Border.all(
          color: isHovered
              ? theme.colorScheme.primary.withValues(alpha: 0.6)
              : theme.colorScheme.outlineVariant,
          width: isHovered ? 1.5 : 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Color bar
          Container(height: 4, color: accentColor),
          // Header
          Padding(
            padding: const EdgeInsets.all(EdenSpacing.space3),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: accentColor),
                ),
                const SizedBox(width: 8),
                Text(column.title, style: theme.textTheme.labelLarge),
                if (column.count != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
                      borderRadius: EdenRadii.borderRadiusFull,
                    ),
                    child: Text(
                      '${column.count}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Cards
          Padding(
            padding: const EdgeInsets.fromLTRB(EdenSpacing.space3, 0, EdenSpacing.space3, EdenSpacing.space3),
            child: Column(
              children: [
                for (int i = 0; i < cardWidgets.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  cardWidgets[i],
                ],
                // Add card button
                if (column.onAddCard != null) ...[
                  if (cardWidgets.isNotEmpty) const SizedBox(height: 8),
                  _AddCardButton(onTap: column.onAddCard!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Wraps an [EdenKanbanCard] in a [LongPressDraggable].
class _DraggableCard extends StatelessWidget {
  const _DraggableCard({
    required this.card,
    required this.columnId,
    required this.cardIndex,
    required this.columnWidth,
    required this.onHoverIndex,
  });

  final EdenKanbanCard card;
  final String columnId;
  final int cardIndex;
  final double columnWidth;
  final ValueChanged<int> onHoverIndex;

  @override
  Widget build(BuildContext context) {
    final dragData = _KanbanDragData(
      cardId: card.id!,
      columnId: columnId,
      cardIndex: cardIndex,
      card: card,
    );

    // Feedback width accounts for column padding.
    final feedbackWidth = columnWidth - EdenSpacing.space3 * 2;

    return DragTarget<_KanbanDragData>(
      onWillAcceptWithDetails: (_) {
        onHoverIndex(cardIndex);
        return false; // We accept at the column level, not card level.
      },
      builder: (context, candidateData, rejectedData) {
        return Semantics(
          label: 'Draggable card: ${card.title}',
          child: LongPressDraggable<_KanbanDragData>(
            data: dragData,
            delay: const Duration(milliseconds: 200),
            hapticFeedbackOnStart: true,
            feedback: card.buildDragFeedback(context, feedbackWidth),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: card,
            ),
            child: card,
          ),
        );
      },
    );
  }
}
