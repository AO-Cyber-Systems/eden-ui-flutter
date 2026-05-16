// Streaming callback types for the Wave-3 chat surface.
//
// Library-owned types: consumers map their gateway's chunks (AODex stream
// chunks, AOSentry stream chunks, OpenAI SSE chunks, ...) to these types via a
// thin adapter. Library code never knows about a specific gateway.

/// Type of a single chunk in a streaming chat response.
enum EdenChatChunkType { content, done }

/// A single chunk emitted by a streaming chat response.
class EdenChatStreamChunk {
  const EdenChatStreamChunk({required this.type, this.content = ''});

  final EdenChatChunkType type;
  final String content;
}

/// Outgoing chat request payload — what the consumer's sendMessage adapter
/// receives. The library captures only the data it needs to track its own
/// conversation state.
class EdenChatRequest {
  const EdenChatRequest({
    required this.conversationId,
    required this.content,
  });

  final String conversationId;
  final String content;
}

/// Signature for the consumer-provided send-message adapter. The library
/// invokes this on each user send and listens to the returned stream.
typedef EdenChatStreamSender = Stream<EdenChatStreamChunk> Function(
    EdenChatRequest request);

/// Signature for the consumer-provided conversation-creation adapter. The
/// library invokes this lazily on first send to obtain a conversation id.
typedef EdenChatConversationCreator = Future<String> Function({
  required String personaId,
  required String title,
});
