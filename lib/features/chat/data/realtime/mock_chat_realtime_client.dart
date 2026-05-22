import 'dart:async';

import 'package:berezhok/features/chat/data/realtime/chat_realtime_client.dart';
import 'package:berezhok/features/chat/domain/chat_message.dart';

class MockChatRealtimeClient implements ChatRealtimeClient {
  @override
  Future<ChatRealtimeConnection> connect(String orderId) async {
    return _MockChatRealtimeConnection(orderId);
  }
}

class _MockChatRealtimeConnection implements ChatRealtimeConnection {
  final String orderId;
  final _controller = StreamController<ChatRealtimeEvent>.broadcast();

  _MockChatRealtimeConnection(this.orderId);

  @override
  Stream<ChatRealtimeEvent> get events => _controller.stream;

  @override
  Future<void> sendMessage(String message) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    _controller.add(
      ChatMessageCreated(
        ChatMessage(
          id: 'mock_sent_${DateTime.now().microsecondsSinceEpoch}',
          orderId: orderId,
          senderType: ChatSenderType.customer,
          senderId: 'customer_1',
          message: message,
          createdAt: DateTime.now(),
        ),
      ),
    );
  }

  @override
  Future<void> markRead(String messageId) async {}

  @override
  Future<void> close() async {
    await _controller.close();
  }
}
