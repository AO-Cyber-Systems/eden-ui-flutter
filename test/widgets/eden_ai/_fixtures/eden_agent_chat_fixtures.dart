// Do NOT regenerate via LLM — hand-built fixtures for EdenAgentChat.
//
// Pure-Dart stream senders + conversation creator stubs used by the chat
// widget tests. No LLM-generated streams; every chunk is hand-coded.

import 'dart:async';

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenAgentChatFixtures {
  EdenAgentChatFixtures._();

  /// Deterministic creator stub. Returns a hard-coded conversation id and
  /// tracks call count for lazy-creation assertions.
  static int createConversationCallCount = 0;

  static void resetCallCounters() {
    createConversationCallCount = 0;
  }

  static Future<String> noopCreator({
    required String personaId,
    required String title,
  }) async {
    createConversationCallCount += 1;
    return 'conv-test-1';
  }

  /// Returns an empty stream — useful when the test does NOT trigger send.
  static Stream<EdenChatStreamChunk> noopStreamSender(EdenChatRequest req) {
    return const Stream<EdenChatStreamChunk>.empty();
  }

  /// Happy-path stream: 'Hello' → ' world' → done.
  static Stream<EdenChatStreamChunk> happyPathStreamSender(
      EdenChatRequest req) async* {
    yield const EdenChatStreamChunk(
        type: EdenChatChunkType.content, content: 'Hello');
    yield const EdenChatStreamChunk(
        type: EdenChatChunkType.content, content: ' world');
    yield const EdenChatStreamChunk(type: EdenChatChunkType.done);
  }

  /// Error stream: 1 content chunk then throws.
  static Stream<EdenChatStreamChunk> errorStreamSender(
      EdenChatRequest req) async* {
    yield const EdenChatStreamChunk(
        type: EdenChatChunkType.content, content: 'Hello');
    throw Exception('boom');
  }
}
