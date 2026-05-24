import 'package:berezhok/features/catalog/domain/location.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses working hours by weekday code', () {
    final location = FoodLocation.fromJson({
      'id': 'loc',
      'name': 'Market',
      'category': {'code': 'grocery', 'name': 'Магазин'},
      'address': 'Москва',
      'coordinates': {'lat': 55.7, 'lng': 37.6},
      'working_hours': {'mon': '08:00-22:00', 'sat': '09:00-23:00'},
    });

    expect(location.workingHours?['mon'], '08:00-22:00');
    expect(location.workingHours?['sat'], '09:00-23:00');
  });
}
