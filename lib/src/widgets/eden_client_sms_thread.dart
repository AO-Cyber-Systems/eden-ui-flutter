import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'eden_message_bubble.dart';
import 'eden_message_input.dart';

/// Direction of a salon SMS message.
enum EdenSmsDirection { inbound, outbound }

/// Outbound delivery-status states.
enum EdenSmsDeliveryStatus { queued, sending, sent, delivered, read, failed }

/// One message in the salon SMS thread.
///
/// Generic across verticals — same widget renders salon SMS, trades dispatcher
/// chat, fuel driver coordination. PHI-redaction variant lives in obj 017.
@immutable
class EdenSmsMessage {
  const EdenSmsMessage({
    required this.id,
    required this.body,
    required this.direction,
    required this.sentAt,
    this.status = EdenSmsDeliveryStatus.sent,
    this.mediaUrls = const [],
    this.authorDisplayName,
  });

  final String id;
  final String body;
  final EdenSmsDirection direction;
  final DateTime sentAt;
  final EdenSmsDeliveryStatus status;
  final List<String> mediaUrls;
  final String? authorDisplayName;
}

/// Outbound message draft emitted by [EdenClientSmsThread.onSend]. Consumer
/// constructs an [EdenSmsMessage] with delivery-status wiring from the wire
/// transport (e.g. Twilio webhooks).
@immutable
class EdenSmsDraft {
  const EdenSmsDraft({required this.body, this.mediaUrls = const []});

  final String body;
  final List<String> mediaUrls;
}

/// Pure helper — formats a date for the day-separator label.
/// Returns "Today" / "Yesterday" / "Wed, May 14" form.
@visibleForTesting
String formatSmsDateSeparator(DateTime date, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final messageDay = DateTime(date.year, date.month, date.day);
  if (messageDay == today) return 'Today';
  if (messageDay == today.subtract(const Duration(days: 1))) return 'Yesterday';
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
}

IconData _statusIcon(EdenSmsDeliveryStatus status) {
  switch (status) {
    case EdenSmsDeliveryStatus.queued:
      return Icons.access_time;
    case EdenSmsDeliveryStatus.sending:
      return Icons.sync;
    case EdenSmsDeliveryStatus.sent:
      return Icons.check;
    case EdenSmsDeliveryStatus.delivered:
    case EdenSmsDeliveryStatus.read:
      return Icons.done_all;
    case EdenSmsDeliveryStatus.failed:
      return Icons.error_outline;
  }
}

Color _statusColor(EdenSmsDeliveryStatus status, ThemeData theme) {
  switch (status) {
    case EdenSmsDeliveryStatus.failed:
      return theme.colorScheme.error;
    case EdenSmsDeliveryStatus.read:
      return theme.colorScheme.primary;
    default:
      return theme.colorScheme.onSurfaceVariant;
  }
}

String _formatTime(DateTime t) {
  final h = t.hour > 12
      ? t.hour - 12
      : (t.hour == 0 ? 12 : t.hour);
  final m = t.minute.toString().padLeft(2, '0');
  final ampm = t.hour >= 12 ? 'PM' : 'AM';
  return '$h:$m $ampm';
}

/// Two-way SMS thread for salon-context customer messaging. Composes obj 003
/// [EdenMessageBubble] + [EdenMessageInput]. Inbound/outbound alignment,
/// delivery-status indicators on outbound, media-attachment thumbnails, grouped
/// date separators, auto-scroll on append.
class EdenClientSmsThread extends StatefulWidget {
  const EdenClientSmsThread({
    super.key,
    required this.messages,
    required this.onSend,
    this.onMediaTap,
    this.onAttachPhoto,
    this.nowOverride,
    this.emptyLabel = 'No messages yet',
  });

  final List<EdenSmsMessage> messages;
  final ValueChanged<EdenSmsDraft> onSend;
  final ValueChanged<String>? onMediaTap;
  final Future<List<String>> Function()? onAttachPhoto;
  final DateTime? nowOverride;
  final String emptyLabel;

  @override
  State<EdenClientSmsThread> createState() => _EdenClientSmsThreadState();
}

class _EdenClientSmsThreadState extends State<EdenClientSmsThread> {
  final _scrollCtrl = ScrollController();
  List<String> _pendingMedia = const [];

  /// Exposed for direct test inspection.
  @visibleForTesting
  ScrollController get scrollController => _scrollCtrl;

  DateTime get _now => widget.nowOverride ?? DateTime.now();

  @override
  void didUpdateWidget(EdenClientSmsThread old) {
    super.didUpdateWidget(old);
    if (widget.messages.length > old.messages.length) {
      _pendingAutoScroll = true;
      WidgetsBinding.instance.addPostFrameCallback(_scheduleAutoScroll);
    }
  }

  bool _pendingAutoScroll = false;

  /// Repeats the jump until [maxScrollExtent] stabilises. ListView.builder
  /// lazily renders rows, so the extent grows over multiple frames as the
  /// freshly-appended message comes into view.
  void _scheduleAutoScroll(Duration _) {
    if (!mounted || !_pendingAutoScroll) return;
    if (!_scrollCtrl.hasClients) {
      // No clients yet — try again next frame.
      WidgetsBinding.instance.addPostFrameCallback(_scheduleAutoScroll);
      return;
    }
    final target = _scrollCtrl.position.maxScrollExtent;
    final current = _scrollCtrl.offset;
    if (current >= target - 0.5) {
      _pendingAutoScroll = false;
      return;
    }
    _scrollCtrl.jumpTo(target);
    // Try one more frame in case lazy items still extend the list.
    WidgetsBinding.instance.addPostFrameCallback(_scheduleAutoScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) {
      return Column(
        children: [
          Expanded(child: Center(child: Text(widget.emptyLabel))),
          _buildInputBar(),
        ],
      );
    }

    // Build a flat list of separators + messages.
    final flat = <_ThreadItem>[];
    DateTime? lastDay;
    for (final msg in widget.messages) {
      final day =
          DateTime(msg.sentAt.year, msg.sentAt.month, msg.sentAt.day);
      if (lastDay == null || day != lastDay) {
        flat.add(_ThreadItem.separator(msg.sentAt));
        lastDay = day;
      }
      flat.add(_ThreadItem.message(msg));
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.all(EdenSpacing.space2),
            itemCount: flat.length,
            itemBuilder: (ctx, i) {
              final item = flat[i];
              if (item.isSeparator) {
                return _DateSeparator(
                    label: formatSmsDateSeparator(item.date!, _now));
              }
              return _MessageRow(
                msg: item.msg!,
                onMediaTap: widget.onMediaTap,
              );
            },
          ),
        ),
        _buildInputBar(),
      ],
    );
  }

  Widget _buildInputBar() {
    return EdenMessageInput(
      onSubmit: (text) {
        widget.onSend(
            EdenSmsDraft(body: text, mediaUrls: List.of(_pendingMedia)));
        setState(() => _pendingMedia = const []);
      },
      onAttachmentTap: widget.onAttachPhoto == null
          ? null
          : () async {
              final added = await widget.onAttachPhoto!();
              setState(() => _pendingMedia = [..._pendingMedia, ...added]);
            },
    );
  }
}

class _ThreadItem {
  _ThreadItem._({this.date, this.msg});
  factory _ThreadItem.separator(DateTime date) => _ThreadItem._(date: date);
  factory _ThreadItem.message(EdenSmsMessage msg) => _ThreadItem._(msg: msg);
  final DateTime? date;
  final EdenSmsMessage? msg;
  bool get isSeparator => date != null;
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: EdenSpacing.space2),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({required this.msg, this.onMediaTap});
  final EdenSmsMessage msg;
  final ValueChanged<String>? onMediaTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOutbound = msg.direction == EdenSmsDirection.outbound;
    final alignment =
        isOutbound ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final align = isOutbound ? Alignment.centerRight : Alignment.centerLeft;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          if (msg.mediaUrls.isNotEmpty)
            Align(
              alignment: align,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final url in msg.mediaUrls)
                      GestureDetector(
                        onTap: onMediaTap == null ? null : () => onMediaTap!(url),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 80,
                            height: 80,
                            child: Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const _MediaFallback(),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          Align(
            alignment: align,
            child: EdenMessageBubble(
              content: msg.body,
              role: isOutbound
                  ? EdenMessageRole.user
                  : EdenMessageRole.assistant,
            ),
          ),
          if (isOutbound)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(msg.sentAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _statusIcon(msg.status),
                    size: 14,
                    color: _statusColor(msg.status, theme),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                _formatTime(msg.sentAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MediaFallback extends StatelessWidget {
  const _MediaFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.image_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 28,
      ),
    );
  }
}
