import 'package:berezhok/core/api/api_client.dart';
import 'package:berezhok/core/api/api_endpoints.dart';
import 'package:berezhok/features/orders/domain/order.dart';
import 'package:berezhok/features/orders/domain/order_list_item.dart';
import 'order_repository.dart';

class ApiOrderRepository implements OrderRepository {
  final ApiClient _apiClient;

  ApiOrderRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<CreateOrderResult> createOrder(String boxId) async {
    final response = await _apiClient.post<_CreateOrderResponseData>(
      ApiEndpoints.createOrder,
      fromJson: _CreateOrderResponseData.fromJson,
      data: {'box_id': boxId},
    );

    if (!response.success || response.data == null) {
      throw Exception(response.error?.message ?? 'Failed to create order');
    }

    final data = response.data!;
    return CreateOrderResult(
      orderId: data.orderId,
      paymentUrl: data.paymentUrl,
      amount: data.amount,
      expiresAt: data.expiresAt,
    );
  }

  @override
  Future<List<OrderListItem>> getOrders({
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _apiClient.getPaginated<OrderListItem>(
      ApiEndpoints.orders,
      fromJson: OrderListItem.fromJson,
      queryParameters: {
        if (status != null) 'status': status,
        'limit': limit,
        'offset': offset,
      },
    );

    if (!response.success) {
      throw Exception(response.error?.message ?? 'Failed to fetch orders');
    }

    return response.items;
  }

  @override
  Future<Order> getOrderDetail(String orderId) async {
    final response = await _apiClient.get<Order>(
      ApiEndpoints.orderDetail(orderId),
      fromJson: Order.fromJson,
    );

    if (!response.success || response.data == null) {
      throw Exception(
          response.error?.message ?? 'Failed to fetch order detail');
    }

    return response.data!;
  }

  @override
  Future<void> confirmPickup(String orderId) async {
    final response = await _apiClient.post(
      ApiEndpoints.confirmPickup(orderId),
      fromJson: (json) => json,
    );

    if (!response.success) {
      throw Exception(response.error?.message ?? 'Failed to confirm pickup');
    }
  }

  @override
  Future<void> openDispute(String orderId, String reason) async {
    final response = await _apiClient.post(
      ApiEndpoints.dispute(orderId),
      fromJson: (json) => json,
      data: {'reason': reason},
    );

    if (!response.success) {
      throw Exception(response.error?.message ?? 'Failed to open dispute');
    }
  }

  @override
  Future<void> createReview(String orderId, int rating, String? comment) async {
    final response = await _apiClient.post(
      ApiEndpoints.createReview,
      fromJson: (json) => json,
      data: {
        'order_id': orderId,
        'rating': rating,
        if (comment != null) 'comment': comment,
      },
    );

    if (!response.success) {
      throw Exception(response.error?.message ?? 'Failed to create review');
    }
  }
}

/// Private model for create order response
class _CreateOrderResponseData {
  final String orderId;
  final String paymentUrl;
  final double amount;
  final DateTime expiresAt;

  _CreateOrderResponseData({
    required this.orderId,
    required this.paymentUrl,
    required this.amount,
    required this.expiresAt,
  });

  factory _CreateOrderResponseData.fromJson(Map<String, dynamic> json) =>
      _CreateOrderResponseData(
        orderId: json['order_id'] as String,
        paymentUrl: json['payment_url'] as String,
        amount: (json['amount'] as num).toDouble(),
        expiresAt: DateTime.parse(json['expires_at'] as String),
      );
}
