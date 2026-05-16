// Do NOT regenerate via LLM — hand-built fixtures for EdenMobileAiFab +
// EdenMobileAiChatSheet. Edit by hand only.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';

class EdenMobileAiFabFixtures {
  EdenMobileAiFabFixtures._();

  /// Three quick action chips (donor parity).
  static List<EdenMobileAiQuickAction> tradesQuickActions() => const [
        EdenMobileAiQuickAction(label: 'Find Parts', icon: Icons.search),
        EdenMobileAiQuickAction(
            label: 'Equipment Info', icon: Icons.info_outline),
        EdenMobileAiQuickAction(
            label: 'Report Issue', icon: Icons.report_outlined),
      ];

  /// Empty quick actions list (renders no chip row).
  static List<EdenMobileAiQuickAction> empty() => const [];

  /// Recorder for sendMessage invocations. Returns a stream-emitting closure
  /// + a List<EdenChatRequest> the test asserts against.
  static (List<EdenChatRequest>, EdenChatStreamSender) recorder() {
    final captured = <EdenChatRequest>[];
    Stream<EdenChatStreamChunk> sender(EdenChatRequest req) {
      captured.add(req);
      return Stream<EdenChatStreamChunk>.fromIterable(const [
        EdenChatStreamChunk(type: EdenChatChunkType.content, content: 'ack'),
        EdenChatStreamChunk(type: EdenChatChunkType.done),
      ]);
    }

    return (captured, sender);
  }

  /// Recorder for createConversation invocations. Returns a creator closure
  /// + a List<String> capturing each title.
  static (List<String>, EdenChatConversationCreator) creatorRecorder() {
    final captured = <String>[];
    Future<String> creator(
        {required String personaId, required String title}) async {
      captured.add(title);
      return 'conv-${captured.length}';
    }

    return (captured, creator);
  }

  /// Inert sendMessage (emits an empty `done` immediately).
  static EdenChatStreamSender inertSender() {
    return (EdenChatRequest req) => Stream<EdenChatStreamChunk>.fromIterable(
        const [EdenChatStreamChunk(type: EdenChatChunkType.done)]);
  }

  /// Inert createConversation (returns a stable id; never inspected).
  static EdenChatConversationCreator inertCreator() {
    return ({required String personaId, required String title}) async =>
        'conv-inert';
  }
}
