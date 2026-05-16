// EdenMobileAiFab — companion-mode bottom-sheet AI chat launcher.
//
// Pairs with objective-003 `EdenAgentChatFab` (full-screen modal variant for
// admin); this widget is the **draggable bottom-sheet** variant for
// on-the-go phone usage. On tap it opens an [EdenMobileAiChatSheet] via
// `showModalBottomSheet(isScrollControlled: true)`.
//
// Library-owned: zero imports of go_router / flutter_riverpod / aodex /
// dio / http / etc. All side-effecting capabilities (streaming, conversation
// creation, persona-change persistence) arrive via consumer-supplied
// callback props.
//
// Donor: AOCyber-Trades/trades-flutter/lib/features/mobile_home/presentation/
// widgets/mobile_ai_fab.dart.

import 'package:flutter/material.dart';

import 'eden_ai/eden_ai_models.dart';
import 'eden_ai/eden_chat_streaming_callbacks.dart';
import 'eden_mobile_ai_chat_sheet.dart';

/// Floating action button that opens an [EdenMobileAiChatSheet] modal
/// bottom sheet.
///
/// **Pairing with objective 003:** this is the *bottom-sheet* (draggable)
/// variant for companion-mode field crew. The objective-003
/// `EdenAgentChatFab` is the *full-screen* modal variant for admin
/// dashboards. They are intentionally separate so each can ship with
/// chrome appropriate to its host (drag handle + persona badge + quick
/// action chips here; full-screen height + EdenPersonaSelector there).
///
/// **Hero tag:** defaults to `'eden_mobile_ai_fab'`. Override [heroTag]
/// when multiple FABs co-exist on the same screen (Flutter's Hero
/// animation requires unique tags within a route).
///
/// **Badge cap:** when [unreadCount] > 9, the badge displays `'9+'`.
/// When [unreadCount] is 0, no badge is rendered.
///
/// **Accent color** is consumer-supplied for vertical theming. Default
/// is donor gold `Color(0xFFD4A853)`. The accent cascades into the
/// chat sheet (send button + chip rail) too.
class EdenMobileAiFab extends StatelessWidget {
  const EdenMobileAiFab({
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
    this.unreadCount = 0,
    this.accentColor = const Color(0xFFD4A853),
    this.heroTag = 'eden_mobile_ai_fab',
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
  final int unreadCount;
  final Color accentColor;
  final Object heroTag;
  final String? greeting;
  final bool isOnline;
  final String offlineMessage;

  String _badgeText(int n) => n > 9 ? '9+' : '$n';

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        FloatingActionButton(
          heroTag: heroTag,
          backgroundColor: accentColor,
          onPressed: () => _openSheet(context),
          tooltip: 'AI Assistant',
          child: const Icon(Icons.auto_awesome, color: Colors.white),
        ),
        if (unreadCount > 0)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                _badgeText(unreadCount),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => EdenMobileAiChatSheet(
        pageContext: pageContext,
        entityType: entityType,
        entityId: entityId,
        entityLabel: entityLabel,
        entityLabelPrefix: entityLabelPrefix,
        activePersona: activePersona,
        onPersonaChanged: onPersonaChanged,
        sendMessage: sendMessage,
        createConversation: createConversation,
        quickActions: quickActions,
        accentColor: accentColor,
        greeting: greeting,
        isOnline: isOnline,
        offlineMessage: offlineMessage,
      ),
    );
  }
}
