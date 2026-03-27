import 'package:berezhok/features/orders/domain/order.dart';
import 'package:berezhok/features/orders/domain/order_list_item.dart';

abstract class OrderRepository {
  Future<CreateOrderResult> createOrder(String boxId);
  Future<List<OrderListItem>> getOrders({
    String? status,
    int limit = 20,
    int offset = 0,
  });
  Future<Order> getOrderDetail(String orderId);
  Future<void> confirmPickup(String orderId);
  Future<void> openDispute(String orderId, String reason);
  Future<void> createReview(String orderId, int rating, String? comment);
}

class CreateOrderResult {
  final String orderId;
  final String paymentUrl;
  final double amount;
  final DateTime expiresAt;

  const CreateOrderResult({
    required this.orderId,
    required this.paymentUrl,
    required this.amount,
    required this.expiresAt,
  });

  @override
  String toString() =>
      'CreateOrderResult(orderId: $orderId, amount: $amount)';
}
