import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';

/// Sender role for message bubbles.
enum EdenMessageRole { user, assistant, system }

/// Status of a message.
enum EdenMessageStatus { sending, sent, delivered, read, failed }

/// An action in the message context menu.
class EdenMessageAction {
  const EdenMessageAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;
}

/// A rich message bubble with author, timestamp, status, streaming, and actions.
class EdenMessageBubble extends StatefulWidget {
  const EdenMessageBubble({
    super.key,
    required this.content,
    this.role = EdenMessageRole.user,
    this.author,
    this.timestamp,
    this.status,
    this.avatar,
    this.isStreaming = false,
    this.isEdited = false,
    this.contentBuilder,
    this.reactions,
    this.onLongPress,
    this.onTap,
    this.actions,
    this.maxWidthFactor = 0.75,
  });

  final String content;
  final EdenMessageRole role;
  final String? author;
  final String? timestamp;
  final EdenMessageStatus? status;
  final Widget? avatar;
  final bool isStreaming;
  final bool isEdited;
  final Widget Function(String content)? contentBuilder;
  final Widget? reactions;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  final List<EdenMessageAction>? actions;
  final double maxWidthFactor;

  @override
  State<EdenMessageBubble> createState() => _EdenMessageBubbleState();
}

class _EdenMessageBubbleState extends State<EdenMessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _streamingController;
  late final Animation<double> _streamingAnimation;

  @override
  void initState() {
    super.initState();
    _streamingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _streamingAnimation = Tween<double>(begin: 1.0, end: 0.6).animate(
      CurvedAnimation(parent: _streamingController, curve: Curves.easeInOut),
    );
    if (widget.isStreaming) {
      _streamingController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(EdenMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isStreaming && !oldWidget.isStreaming) {
      _streamingController.repeat(reverse: true);
    } else if (!widget.isStreaming && oldWidget.isStreaming) {
      _streamingController.stop();
      _streamingController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _streamingController.dispose();
    super.dispose();
  }

  bool get _isUser => widget.role == EdenMessageRole.user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bubbleColors = _resolveBubbleColors(theme, isDark);

    final bubbleContent = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * widget.maxWidthFactor,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space3,
        vertical: EdenSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: bubbleColors.background,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(_isUser ? 16 : 4),
          bottomRight: Radius.circular(_isUser ? 4 : 16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.contentBuilder != null)
            widget.contentBuilder!(widget.content)
          else
            Text(
              widget.content,
              style: TextStyle(
                fontSize: 14,
                color: bubbleColors.foreground,
                height: 1.5,
              ),
            ),
          if (widget.timestamp != null || widget.status != null || widget.isEdited)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.isEdited) ...[
                    Text(
                      'edited',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: bubbleColors.foreground.withValues(alpha: 0.5),
                      ),
                    ),
                    if (widget.timestamp != null)
                      const SizedBox(width: 4),
                  ],
                  if (widget.timestamp != null)
                    Text(
                      widget.timestamp!,
                      style: TextStyle(
                        fontSize: 11,
                        color: bubbleColors.foreground.withValues(alpha: 0.6),
                      ),
                    ),
                  if (widget.status != null) ...[
                    const SizedBox(width: 4),
                    _buildStatusIndicator(bubbleColors.foreground),
                  ],
                ],
              ),
            ),
        ],
      ),
    );

    Widget bubble = widget.isStreaming
        ? AnimatedBuilder(
            animation: _streamingAnimation,
            builder: (context, child) => Opacity(
              opacity: _streamingAnimation.value,
              child: child,
            ),
            child: bubbleContent,
          )
        : bubbleContent;

    if (widget.actions != null && widget.actions!.isNotEmpty) {
      bubble = GestureDetector(
        onTap: widget.onTap,
        onLongPress: () {
          widget.onLongPress?.call();
          _showContextMenu(context);
        },
        child: bubble,
      );
    } else {
      bubble = GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: bubble,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment:
            _isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!_isUser && widget.author != null)
            Padding(
              padding: EdgeInsets.only(
                left: widget.avatar != null ? 48 : 0,
                bottom: 4,
              ),
              child: Text(
                widget.author!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
          Row(
            mainAxisAlignment:
                _isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!_isUser && widget.avatar != null) ...[
                widget.avatar!,
                const SizedBox(width: 8),
              ],
              Flexible(child: bubble),
              if (_isUser && widget.avatar != null) ...[
                const SizedBox(width: 8),
                widget.avatar!,
              ],
            ],
          ),
          if (widget.reactions != null)
            Padding(
              padding: EdgeInsets.only(
                left: !_isUser && widget.avatar != null ? 48 : 0,
                top: 4,
              ),
              child: widget.reactions!,
            ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(Color baseColor) {
    switch (widget.status!) {
      case EdenMessageStatus.sending:
        return SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: baseColor.withValues(alpha: 0.6),
          ),
        );
      case EdenMessageStatus.sent:
        return Icon(Icons.check, size: 14, color: baseColor.withValues(alpha: 0.6));
      case EdenMessageStatus.delivered:
        return Icon(Icons.done_all, size: 14, color: baseColor.withValues(alpha: 0.6));
      case EdenMessageStatus.read:
        return const Icon(Icons.done_all, size: 14, color: Color(0xFF3B82F6));
      case EdenMessageStatus.failed:
        return const Icon(Icons.error_outline, size: 14, color: Color(0xFFEF4444));
    }
  }

  _BubbleColors _resolveBubbleColors(ThemeData theme, bool isDark) {
    switch (widget.role) {
      case EdenMessageRole.user:
        return _BubbleColors(
          theme.colorScheme.primary,
          Colors.white,
        );
      case EdenMessageRole.assistant:
        return _BubbleColors(
          isDark ? EdenColors.neutral[800]! : EdenColors.neutral[100]!,
          theme.colorScheme.onSurface,
        );
      case EdenMessageRole.system:
        return _BubbleColors(
          isDark
              ? EdenColors.neutral[800]!.withValues(alpha: 0.6)
              : EdenColors.neutral[50]!,
          theme.colorScheme.onSurface.withValues(alpha: 0.7),
        );
    }
  }

  void _showContextMenu(BuildContext context) {
    final actions = widget.actions;
    if (actions == null || actions.isEmpty) return;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? EdenColors.neutral[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: EdenColors.neutral[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            for (final action in actions)
              ListTile(
                leading: Icon(
                  action.icon,
                  color: action.isDestructive
                      ? EdenColors.error
                      : theme.colorScheme.onSurface,
                ),
                title: Text(
                  action.label,
                  style: TextStyle(
                    color: action.isDestructive
                        ? EdenColors.error
                        : theme.colorScheme.onSurface,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  action.onTap();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _BubbleColors {
  const _BubbleColors(this.background, this.foreground);
  final Color background;
  final Color foreground;
}
