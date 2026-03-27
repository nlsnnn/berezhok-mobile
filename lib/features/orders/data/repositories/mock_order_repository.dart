import 'package:berezhok/features/orders/domain/order.dart';
import 'package:berezhok/features/orders/domain/order_list_item.dart';
import 'package:berezhok/features/orders/data/repositories/order_repository.dart';

class MockOrderRepository implements OrderRepository {
  final List<Order> _orders = List.of(_initialOrders);

  @override
  Future<CreateOrderResult> createOrder(String boxId) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final order = Order(
      id: 'ord_new_${DateTime.now().millisecondsSinceEpoch}',
      status: OrderStatus.paid,
      pickupCode: 'NW99AB12',
      amount: 199,
      box: const OrderBox(name: 'Новый бокс'),
      location: const OrderLocation(
        name: 'Пекарня Хлебница',
        address: 'Москва, ул. Арбат, 10',
        phone: '+74951234567',
        latitude: 55.7520,
        longitude: 37.5920,
      ),
      pickupTimeStart: DateTime.now().add(const Duration(hours: 2)),
      pickupTimeEnd: DateTime.now().add(const Duration(hours: 3)),
      createdAt: DateTime.now(),
    );

    _orders.insert(0, order);

    return CreateOrderResult(
      orderId: order.id,
      paymentUrl: 'https://pay.berezhok.local/mock/${order.id}',
      amount: order.amount,
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
    );
  }

  @override
  Future<List<OrderListItem>> getOrders({
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    var result = List.of(_orders);
    if (status != null) {
      result = result.where((o) => o.statusKey == status).toList();
    }

    final end = (offset + limit).clamp(0, result.length);
    final items = result.sublist(offset.clamp(0, result.length), end);
    return items.map(_toListItem).toList();
  }

  static OrderListItem _toListItem(Order order) => OrderListItem(
        id: order.id,
        status: order.status,
        pickupCode: order.pickupCode,
        amount: order.amount,
        boxName: order.box.name,
        locationName: order.location.name,
        pickupTimeStart: order.pickupTimeStart,
        createdAt: order.createdAt,
        hasReview: order.hasReview,
      );

  @override
  Future<Order> getOrderDetail(String orderId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    return _orders.firstWhere(
      (o) => o.id == orderId,
      orElse: () => throw Exception('Order $orderId not found'),
    );
  }

  @override
  Future<void> confirmPickup(String orderId) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _updateOrder(orderId, (o) => _copyWithStatus(o, OrderStatus.completed));
  }

  @override
  Future<void> openDispute(String orderId, String reason) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _updateOrder(orderId, (o) => _copyWithStatus(o, OrderStatus.disputed));
  }

  @override
  Future<void> createReview(String orderId, int rating, String? comment) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _updateOrder(orderId, (o) => _copyWithReview(o));
  }

  void _updateOrder(String orderId, Order Function(Order) transform) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) throw Exception('Order $orderId not found');
    _orders[index] = transform(_orders[index]);
  }

  static Order _copyWithStatus(Order order, OrderStatus status) => Order(
        id: order.id,
        status: status,
        pickupCode: order.pickupCode,
        qrCodeUrl: order.qrCodeUrl,
        amount: order.amount,
        box: order.box,
        location: order.location,
        pickupTimeStart: order.pickupTimeStart,
        pickupTimeEnd: order.pickupTimeEnd,
        createdAt: order.createdAt,
        confirmedAt: order.confirmedAt ?? DateTime.now(),
        hasReview: order.hasReview,
      );

  static Order _copyWithReview(Order order) => Order(
        id: order.id,
        status: order.status,
        pickupCode: order.pickupCode,
        qrCodeUrl: order.qrCodeUrl,
        amount: order.amount,
        box: order.box,
        location: order.location,
        pickupTimeStart: order.pickupTimeStart,
        pickupTimeEnd: order.pickupTimeEnd,
        createdAt: order.createdAt,
        confirmedAt: order.confirmedAt,
        hasReview: true,
      );
}

// --- Mock data ---

final _now = DateTime.now();
final _today = DateTime(_now.year, _now.month, _now.day);
final _tomorrow = _today.add(const Duration(days: 1));
final _yesterday = _today.subtract(const Duration(days: 1));

final List<Order> _initialOrders = [
  Order(
    id: 'ord_1',
    status: OrderStatus.confirmed,
    pickupCode: 'AB12CD34',
    amount: 199,
    box: const OrderBox(name: 'Вечерний сюрприз'),
    location: const OrderLocation(
      name: 'Пекарня Хлебница',
      address: 'Москва, ул. Покровка, 19',
      phone: '+74951234567',
      latitude: 55.7601,
      longitude: 37.6478,
    ),
    pickupTimeStart: _today.add(const Duration(hours: 18)),
    pickupTimeEnd: _today.add(const Duration(hours: 19)),
    createdAt: _now.subtract(const Duration(hours: 2)),
    confirmedAt: _now.subtract(const Duration(hours: 1)),
  ),
  Order(
    id: 'ord_2',
    status: OrderStatus.paid,
    pickupCode: 'XK78PL92',
    amount: 149,
    box: const OrderBox(name: 'Утренний бокс'),
    location: const OrderLocation(
      name: 'Кофейня Дабл Би',
      address: 'Москва, ул. Мясницкая, 24/7с1',
      phone: '+74959876543',
      latitude: 55.7628,
      longitude: 37.6365,
    ),
    pickupTimeStart: _tomorrow.add(const Duration(hours: 8)),
    pickupTimeEnd: _tomorrow.add(const Duration(hours: 9)),
    createdAt: _now.subtract(const Duration(hours: 1)),
  ),
  Order(
    id: 'ord_3',
    status: OrderStatus.completed,
    pickupCode: 'MN45QR67',
    amount: 249,
    box: const OrderBox(name: 'Сладкий набор'),
    location: const OrderLocation(
      name: 'Булочная Вольчека',
      address: 'Москва, Б. Никитская ул., 12',
      phone: '+74952223344',
      latitude: 55.7558,
      longitude: 37.6074,
    ),
    pickupTimeStart: _yesterday.add(const Duration(hours: 17)),
    pickupTimeEnd: _yesterday.add(const Duration(hours: 18)),
    createdAt: _yesterday.subtract(const Duration(hours: 6)),
    confirmedAt: _yesterday.subtract(const Duration(hours: 5)),
    hasReview: false,
  ),
  Order(
    id: 'ord_4',
    status: OrderStatus.completed,
    pickupCode: 'JK23HG56',
    amount: 299,
    box: const OrderBox(name: 'Обеденный бокс'),
    location: const OrderLocation(
      name: 'Марукамэ',
      address: 'Москва, ул. Петровка, 30/7',
      phone: '+74955556677',
      latitude: 55.7670,
      longitude: 37.6150,
    ),
    pickupTimeStart: _yesterday.subtract(const Duration(days: 1)).add(const Duration(hours: 12)),
    pickupTimeEnd: _yesterday.subtract(const Duration(days: 1)).add(const Duration(hours: 13)),
    createdAt: _yesterday.subtract(const Duration(days: 1, hours: 4)),
    confirmedAt: _yesterday.subtract(const Duration(days: 1, hours: 3)),
    hasReview: true,
  ),
  Order(
    id: 'ord_5',
    status: OrderStatus.cancelled,
    pickupCode: 'WP89TY12',
    amount: 179,
    box: const OrderBox(name: 'Фруктовый микс'),
    location: const OrderLocation(
      name: 'ВкусВилл',
      address: 'Москва, ул. Маросейка, 6/8',
      latitude: 55.7575,
      longitude: 37.6368,
    ),
    pickupTimeStart: _yesterday.add(const Duration(hours: 15)),
    pickupTimeEnd: _yesterday.add(const Duration(hours: 16)),
    createdAt: _yesterday.subtract(const Duration(hours: 8)),
  ),
  Order(
    id: 'ord_6',
    status: OrderStatus.pickedUp,
    pickupCode: 'RS34UV78',
    amount: 229,
    box: const OrderBox(name: 'Десертный бокс'),
    location: const OrderLocation(
      name: 'Пекарня Хлебница',
      address: 'Москва, ул. Сретенка, 3',
      phone: '+74951234567',
      latitude: 55.7679,
      longitude: 37.6327,
    ),
    pickupTimeStart: _today.add(const Duration(hours: 14)),
    pickupTimeEnd: _today.add(const Duration(hours: 15)),
    createdAt: _now.subtract(const Duration(hours: 4)),
    confirmedAt: _now.subtract(const Duration(hours: 3)),
  ),
  Order(
    id: 'ord_7',
    status: OrderStatus.disputed,
    pickupCode: 'FG56KL90',
    amount: 189,
    box: const OrderBox(name: 'Вечерний набор'),
    location: const OrderLocation(
      name: 'Братья Караваевы',
      address: 'Москва, Тверская ул., 18к1',
      phone: '+74958889900',
      latitude: 55.7647,
      longitude: 37.6043,
    ),
    pickupTimeStart: _yesterday.add(const Duration(hours: 19)),
    pickupTimeEnd: _yesterday.add(const Duration(hours: 20)),
    createdAt: _yesterday.subtract(const Duration(hours: 2)),
    confirmedAt: _yesterday.subtract(const Duration(hours: 1)),
  ),
];
