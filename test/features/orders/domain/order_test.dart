import 'package:flutter_test/flutter_test.dart';

import 'package:berezhok/features/orders/domain/order.dart';

void main() {
  group('Order.canChat', () {
    test('allows chat only while order is confirmed or picked up', () {
      expect(_order(OrderStatus.confirmed).canChat, isTrue);
      expect(_order(OrderStatus.pickedUp).canChat, isTrue);

      expect(_order(OrderStatus.pending).canChat, isFalse);
      expect(_order(OrderStatus.paid).canChat, isFalse);
      expect(_order(OrderStatus.completed).canChat, isFalse);
      expect(_order(OrderStatus.cancelled).canChat, isFalse);
      expect(_order(OrderStatus.refunded).canChat, isFalse);
      expect(_order(OrderStatus.disputed).canChat, isFalse);
    });
  });
}

Order _order(OrderStatus status) {
  return Order(
    id: 'ord_$status',
    status: status,
    pickupCode: 'AB12CD34',
    amount: 199,
    box: const OrderBox(name: 'Вечерний сюрприз'),
    location: const OrderLocation(
      name: 'Пекарня',
      address: 'Москва',
      latitude: 55,
      longitude: 37,
    ),
    pickupTimeStart: DateTime(2026, 5, 13, 18),
    pickupTimeEnd: DateTime(2026, 5, 13, 19),
    createdAt: DateTime(2026, 5, 13, 10),
  );
}
