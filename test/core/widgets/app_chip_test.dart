import 'package:berezhok/core/widgets/app_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('selected chip exposes selected button semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppChip(label: 'Все', isSelected: true)),
      ),
    );

    expect(
      tester.getSemantics(find.text('Все')),
      matchesSemantics(
        label: 'Все',
        hasSelectedState: true,
        isSelected: true,
        isButton: true,
      ),
    );
  });
}
