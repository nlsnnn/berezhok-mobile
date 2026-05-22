import 'package:berezhok/features/chat/domain/chat_message.dart';

abstract class ChatRepository {
  Future<List<ChatMessage>> getMessages(
    String orderId, {
    int limit = 50,
    String? before,
  });

  Future<void> markRead(String orderId, String messageId);
}
