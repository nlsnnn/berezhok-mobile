import 'package:flutter_test/flutter_test.dart';

import 'package:berezhok/features/chat/domain/chat_message.dart';

void main() {
  group('ChatMessage', () {
    test('parses message JSON from chat service', () {
      final message = ChatMessage.fromJson({
        'id': 'msg_1',
        'order_id': 'ord_1',
        'sender_type': 'partner',
        'sender_id': 'partner_1',
        'message': 'Можно забрать до 20:00',
        'created_at': '2026-05-13T10:01:00Z',
      });

      expect(message.id, 'msg_1');
      expect(message.orderId, 'ord_1');
      expect(message.senderType, ChatSenderType.partner);
      expect(message.senderId, 'partner_1');
      expect(message.message, 'Можно забрать до 20:00');
      expect(message.createdAt, DateTime.parse('2026-05-13T10:01:00Z'));
    });

    test('serializes message JSON with snake case keys', () {
      final message = ChatMessage(
        id: 'msg_2',
        orderId: 'ord_2',
        senderType: ChatSenderType.customer,
        senderId: 'customer_1',
        message: 'Здравствуйте',
        createdAt: DateTime.parse('2026-05-13T10:00:00Z'),
      );

      expect(message.toJson(), {
        'id': 'msg_2',
        'order_id': 'ord_2',
        'sender_type': 'customer',
        'sender_id': 'customer_1',
        'message': 'Здравствуйте',
        'created_at': '2026-05-13T10:00:00.000Z',
      });
    });
  });
}
