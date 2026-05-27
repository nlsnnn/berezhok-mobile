import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:berezhok/core/api/api_providers.dart';
import 'package:berezhok/features/orders/domain/order.dart';
import 'package:berezhok/features/orders/domain/order_list_item.dart';
import 'package:berezhok/features/orders/data/repositories/order_repository.dart';
import 'package:berezhok/features/orders/data/repositories/mock_order_repository.dart';
import 'package:berezhok/features/orders/data/repositories/api_order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final useMock = ref.watch(useMockApiProvider);

  if (useMock) {
    return MockOrderRepository();
  } else {
    return ApiOrderRepository(apiClient: ref.watch(apiClientProvider));
  }
});

final ordersProvider =
    AsyncNotifierProvider<OrdersNotifier, List<OrderListItem>>(OrdersNotifier.new);

class OrdersNotifier extends AsyncNotifier<List<OrderListItem>> {
  @override
  Future<List<OrderListItem>> build() async {
    final repo = ref.read(orderRepositoryProvider);
    return repo.getOrders();
  }

  Future<CreateOrderResult> createOrder(String boxId) async {
    final repo = ref.read(orderRepositoryProvider);
    final result = await repo.createOrder(boxId);
    await refresh();
    return result;
  }

  Future<void> confirmPickup(String orderId) async {
    final repo = ref.read(orderRepositoryProvider);
    await repo.confirmPickup(orderId);
    await refresh();
  }

  Future<void> openDispute(String orderId, String reason) async {
    final repo = ref.read(orderRepositoryProvider);
    await repo.openDispute(orderId, reason);
    await refresh();
  }

  Future<void> createReview(
    String orderId,
    int rating,
    String? comment,
  ) async {
    final repo = ref.read(orderRepositoryProvider);
    await repo.createReview(orderId, rating, comment);
    // Сразу помечаем заказ как проверенный локально, чтобы кнопка
    // «Оставить отзыв» исчезла независимо от ответа API.
    ref
        .read(reviewedOrderIdsProvider.notifier)
        .update((ids) => {...ids, orderId});
    await refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(orderRepositoryProvider).getOrders(),
    );
  }
}

final orderDetailProvider =
    FutureProvider.family<Order, String>((ref, orderId) async {
  final repo = ref.read(orderRepositoryProvider);
  return repo.getOrderDetail(orderId);
});

/// Локальный трекер заказов, для которых отзыв уже был успешно отправлен.
/// Используется как защита на случай, если API не возвращает `has_review: true`
/// сразу после создания отзыва.
final reviewedOrderIdsProvider = StateProvider<Set<String>>((ref) => const {});

final activeOrdersProvider = Provider<List<OrderListItem>>((ref) {
  final orders = ref.watch(ordersProvider).valueOrNull ?? [];
  return orders.where((o) => o.isActive).toList();
});

final pastOrdersProvider = Provider<List<OrderListItem>>((ref) {
  final orders = ref.watch(ordersProvider).valueOrNull ?? [];
  return orders.where((o) => !o.isActive).toList();
});
