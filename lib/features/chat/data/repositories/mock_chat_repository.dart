import 'package:berezhok/features/chat/data/repositories/chat_repository.dart';
import 'package:berezhok/features/chat/domain/chat_message.dart';

class MockChatRepository implements ChatRepository {
  final Map<String, List<ChatMessage>> _messagesByOrder = {
    'ord_1': [
      ChatMessage(
        id: 'mock_msg_1',
        orderId: 'ord_1',
        senderType: ChatSenderType.partner,
        senderId: 'partner_1',
        message: 'Заказ подтверждён. Ждём вас в выбранное время.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 35)),
      ),
      ChatMessage(
        id: 'mock_msg_2',
        orderId: 'ord_1',
        senderType: ChatSenderType.customer,
        senderId: 'customer_1',
        message: 'Здравствуйте, можно забрать ближе к концу окна?',
        createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
      ),
      ChatMessage(
        id: 'mock_msg_3',
        orderId: 'ord_1',
        senderType: ChatSenderType.partner,
        senderId: 'partner_1',
        message: 'Да, до 19:00 бокс будет ждать на кассе.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
      ),
    ],
  };

  @override
  Future<List<ChatMessage>> getMessages(
    String orderId, {
    int limit = 50,
    String? before,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final messages = List<ChatMessage>.of(_messagesByOrder[orderId] ?? []);
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final beforeIndex = before == null
        ? messages.length
        : messages.indexWhere((message) => message.id == before);
    final end = beforeIndex < 0 ? messages.length : beforeIndex;
    final start = (end - limit).clamp(0, end);
    return messages.sublist(start, end);
  }

  @override
  Future<void> markRead(String orderId, String messageId) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}
