// EdenMobileAiChatSheet — draggable bottom-sheet AI chat surface.
//
// Composition strategy: **Option B (re-implement stream loop inline).**
// Why Option B over Option A (compose objective-003 EdenAgentChat):
//   1. EdenAgentChat has a fixed `Container(height: 0.6 * screenHeight)`
//      body — not a `DraggableScrollableSheet`. The donor mobile sheet
//      MUST be draggable between 0.4/0.6/0.9 sizes.
//   2. EdenAgentChat hardcodes the entity chip prefix as "Viewing:";
//      the mobile variant requires "Working on:" (or consumer override).
//   3. EdenAgentChat's header uses EdenPersonaSelector (interactive
//      switcher); the mobile variant shows a static persona badge.
//   4. Modifying objective-003 EdenAgentChat is disallowed
//      (no-breaking-changes constraint).
//
// Therefore we re-implement the message-stream loop using the same
// EdenChatStreamSender / EdenChatConversationCreator / EdenChatRequest /
// EdenChatStreamChunk typedefs that objective 003 already defines. The
// chat message rendering reuses objective-003 `EdenChatMessageBubble`.
//
// Donor: AOCyber-Trades/trades-flutter/lib/features/mobile_home/presentation/
// widgets/mobile_ai_chat_sheet.dart. Donor strip list (per Objective 007
// constraints rule 6):
//   - DROP `package:trades/shared/...` imports → use eden_ui exports.
//   - DROP `flutter_riverpod` → callbacks model the consumer wiring.
//   - DROP hardcoded `_quickActions` list → consumer supplies.
//   - DROP hardcoded "Field Tech assistant" greeting copy → optional
//     `greeting` slot OR synthesized from `activePersona.displayLabel`.
//   - DROP "Mock assistant response" sendMessage line — consumer is
//     the only response surface.
//   - DROP hardcoded gold accent → `accentColor` constructor prop.

import 'dart:async';

import 'package:flutter/material.dart';

import 'eden_ai/eden_ai_models.dart';
import 'eden_ai/eden_chat_message_bubble.dart';
import 'eden_ai/eden_chat_streaming_callbacks.dart';

/// A single quick-action chip rendered above the input row.
///
/// Tapping a chip is wired to fire the consumer's `sendMessage` callback
/// with [label] as the request content, so the chip behaves like the
/// user typed the label themselves.
class EdenMobileAiQuickAction {
  const EdenMobileAiQuickAction({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// Draggable bottom-sheet AI chat surface for companion-mode home screens.
///
/// **Layout:** wraps a `DraggableScrollableSheet(initialChildSize: 0.6,
/// minChildSize: 0.4, maxChildSize: 0.9, expand: false)`. The sheet body
/// renders:
///   1. Drag handle (centered grey pill).
///   2. Header: sparkle icon + 'AI Assistant' title + persona badge
///      (static, shows [activePersona].displayLabel) + close button.
///   3. Optional entity chip `"<entityLabelPrefix>: <entityLabel>"`.
///   4. Optional offline banner (when [isOnline] is false).
///   5. Scrolling message list (`EdenChatMessageBubble` per message).
///   6. Horizontal quick-action chip rail (when [quickActions] non-empty).
///   7. Input row (TextField + circular send button tinted [accentColor]).
///
/// **Streaming contract:** identical to objective-003 `EdenAgentChat`:
/// on user send → append user message → lazy-create conversation if
/// needed → append empty assistant message → listen to stream chunks →
/// accumulate `content` chunks into the assistant message → mark
/// streaming complete on `done`.
///
/// **iPhone-narrow safety:** the persona badge label and sheet title
/// are wrapped in `Flexible` + `overflow: TextOverflow.ellipsis` so the
/// header row does not overflow at 390pt with long persona labels.
class EdenMobileAiChatSheet extends StatefulWidget {
  const EdenMobileAiChatSheet({
    super.key,
    required this.activePersona,
    required this.onPersonaChanged,
    required this.sendMessage,
    required this.createConversation,
    required this.pageContext,
    this.entityType,
    this.entityId,
    this.entityLabel,
    this.entityLabelPrefix = 'Working on',
    this.quickActions = const <EdenMobileAiQuickAction>[],
    this.accentColor = const Color(0xFFD4A853),
    this.greeting,
    this.isOnline = true,
    this.offlineMessage = 'AI unavailable — showing offline state',
  });

  final EdenAiPersona activePersona;
  final ValueChanged<EdenAiPersona> onPersonaChanged;
  final EdenChatStreamSender sendMessage;
  final EdenChatConversationCreator createConversation;
  final String pageContext;
  final String? entityType;
  final String? entityId;
  final String? entityLabel;
  final String entityLabelPrefix;
  final List<EdenMobileAiQuickAction> quickActions;
  final Color accentColor;

  /// Optional greeting text. When null, a default greeting is synthesized
  /// from [activePersona].displayLabel. When empty string, no initial
  /// assistant message is inserted (greeting suppressed).
  final String? greeting;

  final bool isOnline;
  final String offlineMessage;

  @override
  State<EdenMobileAiChatSheet> createState() => _EdenMobileAiChatSheetState();
}

class _EdenMobileAiChatSheetState extends State<EdenMobileAiChatSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late final List<EdenChatMessage> _messages;
  StreamSubscription<EdenChatStreamChunk>? _streamSubscription;
  bool _isStreaming = false;
  String? _conversationId;

  @override
  void initState() {
    super.initState();
    _messages = [];
    final greetingText = widget.greeting ??
        "Hi! I'm your ${widget.activePersona.displayLabel} assistant. How can I help?";
    if (greetingText.isNotEmpty) {
      _messages.add(EdenChatMessage(
        id: 'greeting',
        role: EdenChatRole.assistant,
        content: greetingText,
        timestamp: DateTime.now(),
        persona: widget.activePersona,
      ));
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isStreaming) return;
    final persona = widget.activePersona;

    setState(() {
      _messages.add(EdenChatMessage(
        id: 'user_${_messages.length}',
        role: EdenChatRole.user,
        content: trimmed,
        timestamp: DateTime.now(),
      ));
      _controller.clear();
      _isStreaming = true;
    });

    final assistantIndex = _messages.length;
    setState(() {
      _messages.add(EdenChatMessage(
        id: 'asst_$assistantIndex',
        role: EdenChatRole.assistant,
        content: '',
        timestamp: DateTime.now(),
        persona: persona,
      ));
    });
    _scrollToBottom();

    var conversationId = _conversationId;
    if (conversationId == null) {
      conversationId = await widget.createConversation(
        personaId: persona.name,
        title: widget.pageContext,
      );
      if (!mounted) return;
      setState(() => _conversationId = conversationId);
    }

    final request =
        EdenChatRequest(conversationId: conversationId, content: trimmed);
    var accumulated = '';

    _streamSubscription?.cancel();
    _streamSubscription = widget.sendMessage(request).listen(
      (chunk) {
        if (!mounted) return;
        if (chunk.type == EdenChatChunkType.content) {
          accumulated += chunk.content;
          setState(() {
            _messages[assistantIndex] = EdenChatMessage(
              id: 'asst_$assistantIndex',
              role: EdenChatRole.assistant,
              content: accumulated,
              timestamp: DateTime.now(),
              persona: persona,
            );
          });
          _scrollToBottom();
        } else if (chunk.type == EdenChatChunkType.done) {
          if (mounted) setState(() => _isStreaming = false);
        }
      },
      onError: (Object error, StackTrace _) {
        if (!mounted) return;
        setState(() {
          _messages[assistantIndex] = EdenChatMessage(
            id: 'asst_$assistantIndex',
            role: EdenChatRole.assistant,
            content: accumulated.isEmpty
                ? 'Sorry, something went wrong. Please try again.'
                : '$accumulated\n\n[Error: connection interrupted]',
            timestamp: DateTime.now(),
            persona: persona,
          );
          _isStreaming = false;
        });
      },
      onDone: () {
        if (mounted) setState(() => _isStreaming = false);
      },
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final persona = widget.activePersona;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                // Drag handle
                Container(
                  key: const ValueKey('eden_mobile_ai_chat_sheet_drag_handle'),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),

                // Header
                Row(
                  children: [
                    const Icon(Icons.auto_awesome,
                        size: 18, color: Color(0xFFD4A853)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'AI Assistant',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Persona badge (static — not a selector). Wrapped in
                    // Flexible so long labels (e.g. "Operations") ellipsize
                    // before the close button is forced offscreen at 390pt.
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: persona.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          persona.displayLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: persona.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => Navigator.of(ctx).pop(),
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),

                // Offline banner
                if (!widget.isOnline) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off,
                            size: 12, color: theme.colorScheme.error),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            widget.offlineMessage,
                            style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Entity chip
                if (widget.entityLabel != null) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(
                      avatar: Icon(Icons.work_outline,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant),
                      label: Text(
                        '${widget.entityLabelPrefix}: ${widget.entityLabel}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                // Messages
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return EdenChatMessageBubble(message: _messages[index]);
                    },
                  ),
                ),

                // Streaming indicator
                if (_isStreaming)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Thinking...',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Quick action chips
                if (widget.quickActions.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.quickActions.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final action = widget.quickActions[index];
                        return ActionChip(
                          avatar: Icon(action.icon,
                              size: 14, color: widget.accentColor),
                          label: Text(action.label,
                              style: const TextStyle(fontSize: 11)),
                          onPressed: () => _sendMessage(action.label),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                // Input row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        enabled: !_isStreaming,
                        decoration: InputDecoration(
                          hintText: 'Ask a question...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 13),
                        onSubmitted: _sendMessage,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _isStreaming
                            ? widget.accentColor.withValues(alpha: 0.4)
                            : widget.accentColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send,
                            size: 18, color: Colors.white),
                        onPressed: _isStreaming
                            ? null
                            : () => _sendMessage(_controller.text),
                        constraints: const BoxConstraints(
                            minWidth: 36, minHeight: 36),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
