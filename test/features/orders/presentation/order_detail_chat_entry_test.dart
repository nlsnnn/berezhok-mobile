import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:berezhok/features/orders/domain/order.dart';
import 'package:berezhok/features/orders/presentation/pages/order_detail_page.dart';
import 'package:berezhok/features/orders/providers/order_providers.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru');
  });

  group('OrderDetailPage chat entry', () {
    testWidgets('shows chat button for confirmed and picked up orders', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_order(OrderStatus.confirmed)));
      await tester.pumpAndSettle();
      expect(find.text('Чат с заведением'), findsOneWidget);

      await tester.pumpWidget(_app(_order(OrderStatus.pickedUp)));
      await tester.pumpAndSettle();
      expect(find.text('Чат с заведением'), findsOneWidget);
    });

    testWidgets('hides chat button for closed and not-yet-confirmed orders', (
      tester,
    ) async {
      for (final status in [
        OrderStatus.pending,
        OrderStatus.paid,
        OrderStatus.completed,
        OrderStatus.cancelled,
        OrderStatus.refunded,
        OrderStatus.disputed,
      ]) {
        await tester.pumpWidget(_app(_order(status)));
        await tester.pumpAndSettle();
        expect(find.text('Чат с заведением'), findsNothing);
      }
    });
  });
}

Widget _app(Order order) {
  return ProviderScope(
    overrides: [
      orderDetailProvider.overrideWith((ref, orderId) async => order),
    ],
    child: const MaterialApp(home: OrderDetailPage(orderId: 'ord_1')),
  );
}

Order _order(OrderStatus status) {
  return Order(
    id: 'ord_1',
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
