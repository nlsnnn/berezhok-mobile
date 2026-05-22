import 'package:berezhok/core/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows localized label for pending order statuses', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            StatusBadge(status: 'pending'),
            StatusBadge(status: 'pending_payment'),
          ],
        ),
      ),
    );

    expect(find.text('Ожидает оплаты'), findsNWidgets(2));
    expect(find.text('pending'), findsNothing);
    expect(find.text('pending_payment'), findsNothing);
  });
}
