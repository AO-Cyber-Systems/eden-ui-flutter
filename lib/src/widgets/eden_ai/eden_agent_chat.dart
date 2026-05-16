// EdenAgentChat + EdenAgentChatFab — entity-aware AI chat surface.
//
// Riverpod-free / transport-agnostic. Consumers pass streaming + conversation
// adapters as callback props (see EdenChatStreamSender + EdenChatConversation
// Creator). The library handles UI, lazy conversation creation, streaming
// accumulation, and error recovery — but never imports a gateway client.

import 'dart:async';

import 'package:flutter/material.dart';

import 'eden_ai_models.dart';
import 'eden_chat_message_bubble.dart';
import 'eden_chat_streaming_callbacks.dart';
import 'eden_persona_selector.dart';

/// Floating action button that opens an [EdenAgentChat] modal bottom sheet.
///
/// The FAB is a small gold sparkle (matches the donor visual). Tapping it
/// opens the sheet via `showModalBottomSheet(isScrollControlled: true)`.
///
/// **HeroTag:** the FAB uses a stable string tag `'eden_ai_chat_fab'`.
/// Consumers mounting multiple FABs in the same screen MUST override this via
/// the [heroTag] parameter to avoid Flutter Hero collisions.
///
/// All required callbacks are forwarded verbatim to the spawned
/// [EdenAgentChat] sheet — see that class for the contract.
class EdenAgentChatFab extends StatelessWidget {
  const EdenAgentChatFab({
    super.key,
    required this.activePersona,
    required this.onPersonaChanged,
    required this.sendMessage,
    required this.createConversation,
    required this.pageContext,
    this.entityType,
    this.entityId,
    this.entityLabel,
    this.isOnline = true,
    this.offlineMessage = 'AI unavailable — showing offline state',
    this.proposalCard,
    this.heroTag = 'eden_ai_chat_fab',
  });

  final EdenAiPersona activePersona;
  final ValueChanged<EdenAiPersona> onPersonaChanged;
  final EdenChatStreamSender sendMessage;
  final EdenChatConversationCreator createConversation;
  final String pageContext;
  final String? entityType;
  final String? entityId;
  final String? entityLabel;
  final bool isOnline;
  final String offlineMessage;
  final Widget? proposalCard;
  final Object heroTag;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: heroTag,
      mini: true,
      backgroundColor: const Color(0xFFD4A853),
      onPressed: () => _openChat(context),
      tooltip: 'AI Assistant',
      child: const Icon(Icons.auto_awesome, size: 20, color: Colors.white),
    );
  }

  void _openChat(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return EdenAgentChat(
          activePersona: activePersona,
          onPersonaChanged: onPersonaChanged,
          sendMessage: sendMessage,
          createConversation: createConversation,
          pageContext: pageContext,
          entityType: entityType,
          entityId: entityId,
          entityLabel: entityLabel,
          isOnline: isOnline,
          offlineMessage: offlineMessage,
          proposalCard: proposalCard,
        );
      },
    );
  }
}

/// Entity-aware AI chat sheet (Riverpod-free, callback-driven).
///
/// Renders inside a modal bottom sheet at 60% screen height. Composes:
/// - Drag handle.
/// - Header (gold sparkle + 'AI Assistant' + [EdenPersonaSelector] +
///   close button).
/// - Optional offline banner (when [isOnline] is false; copy is
///   [offlineMessage]).
/// - Optional entity context chip (when [entityLabel] is non-null).
/// - Scrollable message list rendered via [EdenChatMessageBubble].
/// - Optional [proposalCard] slot above the input.
/// - Streaming indicator ("Thinking..." + spinner) while a stream is live.
/// - Input row (TextField + send IconButton).
///
/// **Streaming contract:** the library invokes [sendMessage] on each user
/// send, listens to the returned `Stream<EdenChatStreamChunk>`, and:
/// - Appends `chunk.content` to the in-progress assistant message on each
///   `EdenChatChunkType.content` chunk.
/// - Sets `_isStreaming = false` on `EdenChatChunkType.done`.
/// - On error: appends `'\n\n[Error: connection interrupted]'` to whatever
///   was accumulated so far (donor parity) and clears `_isStreaming`.
///
/// **Conversation creation is lazy:** [createConversation] is invoked exactly
/// once — on first send — and the returned id is cached in `_conversationId`
/// for subsequent sends.
///
/// **Persona switching:** the [EdenPersonaSelector] in the header invokes
/// [onPersonaChanged] — the library does NOT mutate any external state, and
/// it does NOT reset `_conversationId`. Consumers wanting "new persona = new
/// conversation" behaviour should re-mount the sheet with a different key.
///
/// **Intent classification removed:** the donor's `classifyIntent` /
/// `evaluateSwitch` / `PersonaSwitchProposalCard` flow is biz-logic and lives
/// outside the library. Consumers wanting persona-switch-proposal UX wrap
/// their own [sendMessage] adapter and surface a [proposalCard] before the
/// stream returns.
class EdenAgentChat extends StatefulWidget {
  const EdenAgentChat({
    super.key,
    required this.activePersona,
    required this.onPersonaChanged,
    required this.sendMessage,
    required this.createConversation,
    required this.pageContext,
    this.entityType,
    this.entityId,
    this.entityLabel,
    this.isOnline = true,
    this.offlineMessage = 'AI unavailable — showing offline state',
    this.proposalCard,
  });

  final EdenAiPersona activePersona;
  final ValueChanged<EdenAiPersona> onPersonaChanged;
  final EdenChatStreamSender sendMessage;
  final EdenChatConversationCreator createConversation;
  final String pageContext;
  final String? entityType;
  final String? entityId;
  final String? entityLabel;
  final bool isOnline;
  final String offlineMessage;
  final Widget? proposalCard;

  @override
  State<EdenAgentChat> createState() => _EdenAgentChatState();
}

class _EdenAgentChatState extends State<EdenAgentChat> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late final List<EdenChatMessage> _messages;
  StreamSubscription<EdenChatStreamChunk>? _streamSubscription;
  bool _isStreaming = false;
  String? _conversationId;

  @override
  void initState() {
    super.initState();
    _messages = [
      EdenChatMessage(
        id: 'greeting',
        role: EdenChatRole.assistant,
        content:
            'Hi! I\'m your ${widget.activePersona.displayLabel} assistant. How can I help?',
        timestamp: DateTime.now(),
        persona: widget.activePersona,
      ),
    ];
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isStreaming) return;

    final persona = widget.activePersona;

    setState(() {
      _messages.add(EdenChatMessage(
        id: 'user_${_messages.length}',
        role: EdenChatRole.user,
        content: text,
        timestamp: DateTime.now(),
      ));
      _controller.clear();
      _isStreaming = true;
    });

    // Add empty assistant message to fill with stream content.
    final assistantMsgIndex = _messages.length;
    setState(() {
      _messages.add(EdenChatMessage(
        id: 'asst_$assistantMsgIndex',
        role: EdenChatRole.assistant,
        content: '',
        timestamp: DateTime.now(),
        persona: persona,
      ));
    });

    _scrollToBottom();

    // Ensure we have a conversation id (lazy creation).
    var conversationId = _conversationId;
    if (conversationId == null) {
      conversationId = await widget.createConversation(
        personaId: persona.name,
        title: widget.pageContext,
      );
      if (!mounted) return;
      setState(() => _conversationId = conversationId);
    }

    final request = EdenChatRequest(
      conversationId: conversationId,
      content: text,
    );

    var accumulated = '';

    _streamSubscription?.cancel();
    _streamSubscription = widget.sendMessage(request).listen(
      (chunk) {
        if (!mounted) return;

        if (chunk.type == EdenChatChunkType.content) {
          accumulated += chunk.content;
          setState(() {
            _messages[assistantMsgIndex] = EdenChatMessage(
              id: 'asst_$assistantMsgIndex',
              role: EdenChatRole.assistant,
              content: accumulated,
              timestamp: DateTime.now(),
              persona: persona,
            );
          });
          _scrollToBottom();
        } else if (chunk.type == EdenChatChunkType.done) {
          if (mounted) {
            setState(() => _isStreaming = false);
          }
        }
      },
      onError: (Object error, StackTrace _) {
        if (!mounted) return;
        setState(() {
          _messages[assistantMsgIndex] = EdenChatMessage(
            id: 'asst_$assistantMsgIndex',
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
        if (mounted) {
          setState(() => _isStreaming = false);
        }
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

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          // Drag handle.
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header.
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
              EdenPersonaSelector(
                activePersona: widget.activePersona,
                onChanged: widget.onPersonaChanged,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => Navigator.of(context).pop(),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),

          // Offline banner.
          if (!widget.isOnline) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
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
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Entity context chip.
          if (widget.entityLabel != null) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                avatar: Icon(Icons.visibility,
                    size: 14, color: theme.colorScheme.onSurfaceVariant),
                label: Text(
                  'Viewing: ${widget.entityLabel}',
                  style: const TextStyle(fontSize: 11),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
          const SizedBox(height: 8),

          // Messages.
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return EdenChatMessageBubble(message: _messages[index]);
              },
            ),
          ),
          const SizedBox(height: 8),

          // Proposal slot (consumer-rendered).
          if (widget.proposalCard != null) widget.proposalCard!,

          // Streaming indicator.
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

          // Input.
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
                      horizontal: 12,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 13),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send, size: 18),
                onPressed: _isStreaming ? null : _sendMessage,
                color: const Color(0xFFD4A853),
                constraints:
                    const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
