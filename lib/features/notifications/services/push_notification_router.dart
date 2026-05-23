abstract final class PushNotificationRouter {
  static String? pathFromData(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final orderId = (data['order_id'] as String?)?.trim();

    if (orderId == null || orderId.isEmpty) return null;

    final encodedOrderId = Uri.encodeComponent(orderId);
    return switch (type) {
      'order' => '/orders/$encodedOrderId',
      'chat' => '/orders/$encodedOrderId/chat',
      _ => null,
    };
  }
}
