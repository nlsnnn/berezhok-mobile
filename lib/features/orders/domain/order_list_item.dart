import 'package:berezhok/features/orders/domain/order.dart';

class OrderListItem {
  final String id;
  final OrderStatus status;
  final String pickupCode;
  final double amount;
  final String boxName;
  final String locationName;
  final DateTime pickupTimeStart;
  final DateTime createdAt;
  final bool hasReview;

  const OrderListItem({
    required this.id,
    required this.status,
    required this.pickupCode,
    required this.amount,
    required this.boxName,
    required this.locationName,
    required this.pickupTimeStart,
    required this.createdAt,
    this.hasReview = false,
  });

  bool get isActive =>
      status == OrderStatus.paid ||
      status == OrderStatus.confirmed ||
      status == OrderStatus.pickedUp;

  String get statusKey => switch (status) {
        OrderStatus.pickedUp => 'picked_up',
        _ => status.name,
      };

  factory OrderListItem.fromJson(Map<String, dynamic> json) => OrderListItem(
        id: json['id'] as String,
        status: _parseStatus(json['status'] as String),
        pickupCode: json['pickup_code'] as String,
        amount: (json['amount'] as num).toDouble(),
        boxName: json['box_name'] as String? ?? '',
        locationName: json['location_name'] as String? ?? '',
        pickupTimeStart: DateTime.parse(json['pickup_time_start'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        hasReview: json['has_review'] as bool? ?? false,
      );

  static OrderStatus _parseStatus(String value) => switch (value) {
        'pending' => OrderStatus.pending,
        'paid' => OrderStatus.paid,
        'confirmed' => OrderStatus.confirmed,
        'picked_up' => OrderStatus.pickedUp,
        'completed' => OrderStatus.completed,
        'cancelled' => OrderStatus.cancelled,
        'refunded' => OrderStatus.refunded,
        'disputed' => OrderStatus.disputed,
        _ => OrderStatus.pending,
      };

  @override
  String toString() => 'OrderListItem(id: $id, status: $statusKey)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderListItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
