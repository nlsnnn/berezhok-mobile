import 'package:flutter_test/flutter_test.dart';

import 'package:berezhok/features/orders/domain/order.dart';
import 'package:berezhok/features/orders/domain/order_list_item.dart';

void main() {
  group('Order status parsing', () {
    test('accepts pending_payment from API as pending', () {
      expect(
        Order.fromJson(_orderJson('pending_payment')).status,
        OrderStatus.pending,
      );
      expect(
        OrderListItem.fromJson(_orderListItemJson('pending_payment')).status,
        OrderStatus.pending,
      );
    });
  });

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

Map<String, dynamic> _orderJson(String status) {
  return {
    'id': 'ord_1',
    'status': status,
    'pickup_code': 'AB12CD34',
    'amount': 199,
    'box': {'name': 'Вечерний сюрприз'},
    'location': {
      'name': 'Пекарня',
      'address': 'Москва',
      'latitude': 55,
      'longitude': 37,
    },
    'pickup_time_start': '2026-05-13T18:00:00.000',
    'pickup_time_end': '2026-05-13T19:00:00.000',
    'created_at': '2026-05-13T10:00:00.000',
  };
}

Map<String, dynamic> _orderListItemJson(String status) {
  return {
    'id': 'ord_1',
    'status': status,
    'pickup_code': 'AB12CD34',
    'amount': 199,
    'box_name': 'Вечерний сюрприз',
    'location_name': 'Пекарня',
    'pickup_time_start': '2026-05-13T18:00:00.000',
    'created_at': '2026-05-13T10:00:00.000',
  };
}
