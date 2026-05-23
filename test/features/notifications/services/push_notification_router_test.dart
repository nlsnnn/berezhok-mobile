import 'package:flutter_test/flutter_test.dart';

import 'package:berezhok/features/notifications/services/push_notification_router.dart';

void main() {
  group('PushNotificationRouter.pathFromData', () {
    test('returns order detail path for order notification', () {
      final path = PushNotificationRouter.pathFromData({
        'type': 'order',
        'order_id': 'ord-123',
      });

      expect(path, '/orders/ord-123');
    });

    test('returns chat path for chat notification', () {
      final path = PushNotificationRouter.pathFromData({
        'type': 'chat',
        'order_id': 'ord-123',
      });

      expect(path, '/orders/ord-123/chat');
    });

    test('returns null for unsupported notification type', () {
      final path = PushNotificationRouter.pathFromData({
        'type': 'promo',
        'order_id': 'ord-123',
      });

      expect(path, isNull);
    });

    test('returns null when order id is missing', () {
      final path = PushNotificationRouter.pathFromData({'type': 'order'});

      expect(path, isNull);
    });
  });
}
