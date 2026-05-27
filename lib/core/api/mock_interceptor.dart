/// Dio interceptor that returns mock data instead of hitting the real API.
///
/// Used during development and testing. Add it to [ApiClient] via
/// `extraInterceptors: [MockInterceptor()]`.
library;

import 'package:dio/dio.dart';

class _MockResponse {
  final int statusCode;
  final Map<String, dynamic> data;

  const _MockResponse({
    this.statusCode = 200,
    required this.data,
  });
}

class MockInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final response = _getMockResponse(options);
    if (response != null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        handler.resolve(Response(
          requestOptions: options,
          statusCode: response.statusCode,
          data: response.data,
        ));
      });
    } else {
      handler.next(options);
    }
  }

  _MockResponse? _getMockResponse(RequestOptions options) {
    final path = options.path;
    final method = options.method.toUpperCase();

    // -------------------------------------------------------------------------
    // Auth
    // -------------------------------------------------------------------------
    if (path == '/auth/customer/send-code' && method == 'POST') {
      return _MockResponse(data: {
        'success': true,
        'data': {
          'expires_in': 300,
        },
      });
    }

    if (path == '/auth/customer/login' && method == 'POST') {
      return _MockResponse(data: {
        'success': true,
        'data': {
          'access_token':
              'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJjMWEyYjNjNC1kNWU2LTRmNzgtYTliMC1jMWQyZTNmNGc1aDYiLCJleHAiOjE3NDUwMDAwMDB9.mock_signature',
          'refresh_token': 'rt_mock_a1b2c3d4e5f6g7h8i9j0',
          'token_type': 'Bearer',
          'expires_in': 3600,
          'user': {
            'id': 'c1a2b3c4-d5e6-4f78-a9b0-c1d2e3f4g5h6',
            'phone': '+7 (999) 123-45-67',
            'first_name': 'Алексей',
            'last_name': 'Иванов',
            'email': 'alexey@example.com',
            'avatar_url': null,
            'created_at': '2025-06-15T10:30:00Z',
          },
        },
      });
    }

    // -------------------------------------------------------------------------
    // Customer profile
    // -------------------------------------------------------------------------
    if (path == '/customer/profile' && method == 'GET') {
      return _MockResponse(data: {
        'success': true,
        'data': _mockUserProfile(),
      });
    }

    if (path == '/customer/profile' && method == 'PATCH') {
      return _MockResponse(data: {
        'success': true,
        'data': {
          ..._mockUserProfile(),
          // Merge any fields the client sent.
          if (options.data is Map<String, dynamic>)
            ...options.data as Map<String, dynamic>,
        },
      });
    }

    // -------------------------------------------------------------------------
    // Locations
    // -------------------------------------------------------------------------
    if (path == '/customer/locations' && method == 'GET') {
      return _MockResponse(data: {
        'success': true,
        'data': {
          'items': _mockLocations(),
          'pagination': {
            'total': 12,
            'limit': 20,
            'offset': 0,
            'has_more': false,
          },
        },
      });
    }

    // Location detail — /customer/locations/{id}
    final locationDetailMatch =
        RegExp(r'^/customer/locations/([\w-]+)$').firstMatch(path);
    if (locationDetailMatch != null && method == 'GET') {
      final id = locationDetailMatch.group(1)!;
      return _MockResponse(data: {
        'success': true,
        'data': _mockLocationDetail(id),
      });
    }

    // -------------------------------------------------------------------------
    // Orders
    // -------------------------------------------------------------------------
    if (path == '/customer/orders' && method == 'POST') {
      return _MockResponse(
        statusCode: 201,
        data: {
          'success': true,
          'data': {
            'id': 'ord-a1b2c3d4-e5f6-4789-abcd-ef0123456789',
            'status': 'pending_payment',
            'payment_url': 'https://pay.berezhok.ru/checkout/mock-session-id',
            'created_at': DateTime.now().toUtc().toIso8601String(),
          },
        },
      );
    }

    if (path == '/customer/orders' && method == 'GET') {
      return _MockResponse(data: {
        'success': true,
        'data': {
          'items': _mockOrders(),
          'pagination': {
            'total': 7,
            'limit': 20,
            'offset': 0,
            'has_more': false,
          },
        },
      });
    }

    // Order detail — /customer/orders/{id}
    final orderDetailMatch =
        RegExp(r'^/customer/orders/([\w-]+)$').firstMatch(path);
    if (orderDetailMatch != null && method == 'GET') {
      final id = orderDetailMatch.group(1)!;
      return _MockResponse(data: {
        'success': true,
        'data': _mockOrderDetail(id),
      });
    }

    // Confirm pickup — /customer/orders/{id}/confirm-pickup
    final confirmPickupMatch =
        RegExp(r'^/customer/orders/([\w-]+)/confirm-pickup$').firstMatch(path);
    if (confirmPickupMatch != null && method == 'POST') {
      return _MockResponse(data: {
        'success': true,
        'data': {
          'status': 'completed',
          'picked_up_at': DateTime.now().toUtc().toIso8601String(),
        },
      });
    }

    // Dispute — /customer/orders/{id}/dispute
    final disputeMatch =
        RegExp(r'^/customer/orders/([\w-]+)/dispute$').firstMatch(path);
    if (disputeMatch != null && method == 'POST') {
      return _MockResponse(data: {
        'success': true,
        'data': {
          'status': 'disputed',
          'dispute_id': 'dsp-f1e2d3c4-b5a6-4978-8765-432109876543',
          'created_at': DateTime.now().toUtc().toIso8601String(),
        },
      });
    }

    // -------------------------------------------------------------------------
    // Reviews
    // -------------------------------------------------------------------------
    if (path == '/customer/reviews' && method == 'POST') {
      return _MockResponse(
        statusCode: 201,
        data: {
          'success': true,
          'data': {
            'id': 'rev-11223344-5566-4778-99aa-bbccddeeff00',
            'rating': (options.data as Map<String, dynamic>?)?['rating'] ?? 5,
            'comment':
                (options.data as Map<String, dynamic>?)?['comment'] ?? '',
            'created_at': DateTime.now().toUtc().toIso8601String(),
          },
        },
      );
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Mock data builders
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _mockUserProfile() => {
        'id': 'c1a2b3c4-d5e6-4f78-a9b0-c1d2e3f4g5h6',
        'phone': '+7 (999) 123-45-67',
        'first_name': 'Алексей',
        'last_name': 'Иванов',
        'email': 'alexey@example.com',
        'avatar_url': null,
        'orders_count': 12,
        'reviews_count': 5,
        'saved_amount': 2340,
        'created_at': '2025-06-15T10:30:00Z',
      };

  List<Map<String, dynamic>> _mockLocations() => [
        {
          'id': 'loc-a1000001-bbbb-4ccc-dddd-eeeeeeee0001',
          'name': 'Пекарня «Хлеб Насущный»',
          'category': 'bakery',
          'address': 'ул. Большая Дмитровка, 7/5с1, Москва',
          'latitude': 55.7602,
          'longitude': 37.6132,
          'rating': 4.7,
          'reviews_count': 84,
          'active_boxes_count': 3,
          'distance': 0.4,
          'image_url':
              'https://images.berezhok.ru/locations/hleb-nasushchnyy.jpg',
          'working_hours': '07:00–22:00',
        },
        {
          'id': 'loc-a1000001-bbbb-4ccc-dddd-eeeeeeee0002',
          'name': 'Кофейня «Даблби»',
          'category': 'cafe',
          'address': 'Покровка, 17, Москва',
          'latitude': 55.7590,
          'longitude': 37.6450,
          'rating': 4.5,
          'reviews_count': 62,
          'active_boxes_count': 1,
          'distance': 0.9,
          'image_url': 'https://images.berezhok.ru/locations/dablbi.jpg',
          'working_hours': '08:00–23:00',
        },
        {
          'id': 'loc-a1000001-bbbb-4ccc-dddd-eeeeeeee0003',
          'name': 'Ресторан «Белый Кролик»',
          'category': 'restaurant',
          'address': 'Смоленская пл., 3, Москва',
          'latitude': 55.7468,
          'longitude': 37.5823,
          'rating': 4.9,
          'reviews_count': 210,
          'active_boxes_count': 2,
          'distance': 1.8,
          'image_url':
              'https://images.berezhok.ru/locations/belyy-krolik.jpg',
          'working_hours': '12:00–00:00',
        },
        {
          'id': 'loc-a1000001-bbbb-4ccc-dddd-eeeeeeee0004',
          'name': 'Продукты «ВкусВилл»',
          'category': 'grocery',
          'address': 'ул. Мясницкая, 30/1/2с2, Москва',
          'latitude': 55.7638,
          'longitude': 37.6362,
          'rating': 4.3,
          'reviews_count': 45,
          'active_boxes_count': 5,
          'distance': 0.6,
          'image_url': 'https://images.berezhok.ru/locations/vkusvill.jpg',
          'working_hours': '08:00–23:00',
        },
        {
          'id': 'loc-a1000001-bbbb-4ccc-dddd-eeeeeeee0005',
          'name': 'Кафе «Братья Караваевы»',
          'category': 'cafe',
          'address': 'Маросейка, 2/15с1, Москва',
          'latitude': 55.7570,
          'longitude': 37.6340,
          'rating': 4.4,
          'reviews_count': 97,
          'active_boxes_count': 2,
          'distance': 0.7,
          'image_url':
              'https://images.berezhok.ru/locations/bratya-karavaevi.jpg',
          'working_hours': '08:00–22:00',
        },
        {
          'id': 'loc-a1000001-bbbb-4ccc-dddd-eeeeeeee0006',
          'name': 'Отель «Метрополь»',
          'category': 'hotel',
          'address': 'Театральный пр-д, 2, Москва',
          'latitude': 55.7581,
          'longitude': 37.6216,
          'rating': 4.8,
          'reviews_count': 31,
          'active_boxes_count': 1,
          'distance': 0.3,
          'image_url': 'https://images.berezhok.ru/locations/metropol.jpg',
          'working_hours': '06:00–23:00',
        },
        {
          'id': 'loc-a1000001-bbbb-4ccc-dddd-eeeeeeee0007',
          'name': 'Пекарня «Волконский»',
          'category': 'bakery',
          'address': 'Большая Садовая ул., 2/46, Москва',
          'latitude': 55.7690,
          'longitude': 37.5945,
          'rating': 4.6,
          'reviews_count': 112,
          'active_boxes_count': 4,
          'distance': 1.2,
          'image_url': 'https://images.berezhok.ru/locations/volkonskiy.jpg',
          'working_hours': '07:30–21:30',
        },
        {
          'id': 'loc-a1000001-bbbb-4ccc-dddd-eeeeeeee0008',
          'name': 'Ресторан «Кофемания»',
          'category': 'restaurant',
          'address': 'ул. Большая Никитская, 13, Москва',
          'latitude': 55.7562,
          'longitude': 37.6035,
          'rating': 4.5,
          'reviews_count': 178,
          'active_boxes_count': 2,
          'distance': 1.0,
          'image_url': 'https://images.berezhok.ru/locations/kofemaniya.jpg',
          'working_hours': '08:00–00:00',
        },
        {
          'id': 'loc-a1000001-bbbb-4ccc-dddd-eeeeeeee0009',
          'name': 'Кафе «Андерсон»',
          'category': 'cafe',
          'address': 'ул. Остоженка, 56/1с1, Москва',
          'latitude': 55.7380,
          'longitude': 37.5925,
          'rating': 4.2,
          'reviews_count': 53,
          'active_boxes_count': 3,
          'distance': 2.1,
          'image_url': 'https://images.berezhok.ru/locations/anderson.jpg',
          'working_hours': '09:00–22:00',
        },
        {
          'id': 'loc-a1000001-bbbb-4ccc-dddd-eeeeeeee0010',
          'name': 'Продукты «Азбука Вкуса»',
          'category': 'grocery',
          'address': 'Тверская ул., 18к1, Москва',
          'latitude': 55.7655,
          'longitude': 37.6065,
          'rating': 4.4,
          'reviews_count': 67,
          'active_boxes_count': 6,
          'distance': 0.8,
          'image_url':
              'https://images.berezhok.ru/locations/azbuka-vkusa.jpg',
          'working_hours': '08:00–23:00',
        },
        {
          'id': 'loc-a1000001-bbbb-4ccc-dddd-eeeeeeee0011',
          'name': 'Пекарня «Булка»',
          'category': 'bakery',
          'address': 'Новослободская ул., 24, Москва',
          'latitude': 55.7775,
          'longitude': 37.5980,
          'rating': 4.3,
          'reviews_count': 39,
          'active_boxes_count': 2,
          'distance': 1.9,
          'image_url': 'https://images.berezhok.ru/locations/bulka.jpg',
          'working_hours': '07:00–21:00',
        },
        {
          'id': 'loc-a1000001-bbbb-4ccc-dddd-eeeeeeee0012',
          'name': 'Ресторан «Турандот»',
          'category': 'restaurant',
          'address': 'Тверской бульвар, 26с3, Москва',
          'latitude': 55.7620,
          'longitude': 37.6000,
          'rating': 4.8,
          'reviews_count': 256,
          'active_boxes_count': 1,
          'distance': 1.1,
          'image_url': 'https://images.berezhok.ru/locations/turandot.jpg',
          'working_hours': '12:00–00:00',
        },
      ];

  Map<String, dynamic> _mockLocationDetail(String id) {
    // Find location from the list or create a fallback.
    final locations = _mockLocations();
    final location = locations.firstWhere(
      (l) => l['id'] == id,
      orElse: () => locations.first,
    );

    return {
      ...location,
      'description':
          'Уютное заведение в самом центре Москвы. Каждый день мы спасаем '
              'продукты от утилизации и предлагаем их вам в виде сюрприз-боксов '
              'по сниженным ценам.',
      'surprise_boxes': _mockBoxesForLocation(id),
    };
  }

  List<Map<String, dynamic>> _mockBoxesForLocation(String id) {
    // Generate 1-3 boxes depending on id hash.
    final hash = id.hashCode.abs();
    final count = (hash % 3) + 1;

    final allBoxes = <Map<String, dynamic>>[
      {
        'id': 'box-11111111-aaaa-4bbb-cccc-dddddddd0001',
        'name': 'Вечерний сюрприз',
        'description':
            'Выпечка и десерты, приготовленные сегодня. Состав — сюрприз!',
        'original_price': 800,
        'discounted_price': 299,
        'category': 'bakery',
        'quantity_available': 3,
        'pickup_start': '19:00',
        'pickup_end': '21:00',
        'image_url':
            'https://images.berezhok.ru/boxes/evening-surprise.jpg',
      },
      {
        'id': 'box-11111111-aaaa-4bbb-cccc-dddddddd0002',
        'name': 'Утренний бокс',
        'description':
            'Свежий хлеб, круассаны и булочки от нашего пекаря. Идеально к кофе.',
        'original_price': 600,
        'discounted_price': 199,
        'category': 'bakery',
        'quantity_available': 5,
        'pickup_start': '08:00',
        'pickup_end': '10:00',
        'image_url': 'https://images.berezhok.ru/boxes/morning-box.jpg',
      },
      {
        'id': 'box-11111111-aaaa-4bbb-cccc-dddddddd0003',
        'name': 'Сладкий набор',
        'description':
            'Торты, пирожные и печенье — ассортимент дня. Порция на 2-3 человека.',
        'original_price': 1200,
        'discounted_price': 449,
        'category': 'dessert',
        'quantity_available': 2,
        'pickup_start': '17:00',
        'pickup_end': '20:00',
        'image_url': 'https://images.berezhok.ru/boxes/sweet-set.jpg',
      },
    ];

    return allBoxes.take(count).toList();
  }

  List<Map<String, dynamic>> _mockOrders() => [
        {
          'id': 'ord-a1000001-aaaa-4bbb-cccc-dddddddd0001',
          'status': 'completed',
          'location_name': 'Пекарня «Хлеб Насущный»',
          'box_name': 'Вечерний сюрприз',
          'price': 299,
          'created_at': '2026-03-10T18:30:00Z',
          'pickup_start': '2026-03-10T19:00:00Z',
          'pickup_end': '2026-03-10T21:00:00Z',
        },
        {
          'id': 'ord-a1000001-aaaa-4bbb-cccc-dddddddd0002',
          'status': 'ready_for_pickup',
          'location_name': 'Кофейня «Даблби»',
          'box_name': 'Утренний бокс',
          'price': 199,
          'created_at': '2026-03-12T07:15:00Z',
          'pickup_start': '2026-03-12T08:00:00Z',
          'pickup_end': '2026-03-12T10:00:00Z',
        },
        {
          'id': 'ord-a1000001-aaaa-4bbb-cccc-dddddddd0003',
          'status': 'pending_payment',
          'location_name': 'Ресторан «Белый Кролик»',
          'box_name': 'Сладкий набор',
          'price': 449,
          'created_at': '2026-03-12T12:00:00Z',
          'pickup_start': '2026-03-12T17:00:00Z',
          'pickup_end': '2026-03-12T20:00:00Z',
        },
        {
          'id': 'ord-a1000001-aaaa-4bbb-cccc-dddddddd0004',
          'status': 'cancelled',
          'location_name': 'Продукты «ВкусВилл»',
          'box_name': 'Вечерний сюрприз',
          'price': 299,
          'created_at': '2026-03-08T16:00:00Z',
          'pickup_start': '2026-03-08T19:00:00Z',
          'pickup_end': '2026-03-08T21:00:00Z',
        },
        {
          'id': 'ord-a1000001-aaaa-4bbb-cccc-dddddddd0005',
          'status': 'completed',
          'location_name': 'Кафе «Братья Караваевы»',
          'box_name': 'Утренний бокс',
          'price': 199,
          'created_at': '2026-03-05T08:00:00Z',
          'pickup_start': '2026-03-05T08:00:00Z',
          'pickup_end': '2026-03-05T10:00:00Z',
        },
        {
          'id': 'ord-a1000001-aaaa-4bbb-cccc-dddddddd0006',
          'status': 'disputed',
          'location_name': 'Пекарня «Волконский»',
          'box_name': 'Сладкий набор',
          'price': 449,
          'created_at': '2026-03-01T17:30:00Z',
          'pickup_start': '2026-03-01T17:00:00Z',
          'pickup_end': '2026-03-01T20:00:00Z',
        },
        {
          'id': 'ord-a1000001-aaaa-4bbb-cccc-dddddddd0007',
          'status': 'completed',
          'location_name': 'Ресторан «Кофемания»',
          'box_name': 'Вечерний сюрприз',
          'price': 299,
          'created_at': '2026-02-28T19:00:00Z',
          'pickup_start': '2026-02-28T19:00:00Z',
          'pickup_end': '2026-02-28T21:00:00Z',
        },
      ];

  Map<String, dynamic> _mockOrderDetail(String id) {
    final orders = _mockOrders();
    final order = orders.firstWhere(
      (o) => o['id'] == id,
      orElse: () => orders.first,
    );

    final isPending = order['status'] == 'pending_payment';
    return {
      ...order,
      'amount': order['price'],
      if (!isPending) 'pickup_code': '7842',
      if (!isPending) 'qr_code_url': 'https://api.berezhok.ru/v1/orders/$id/qr',
      if (isPending) 'payment_url': 'https://pay.berezhok.ru/checkout/mock-$id',
      'location': {
        'id': 'loc-a1000001-bbbb-4ccc-dddd-eeeeeeee0001',
        'name': order['location_name'],
        'address': 'ул. Большая Дмитровка, 7/5с1, Москва',
        'latitude': 55.7602,
        'longitude': 37.6132,
      },
      'box': {
        'id': 'box-11111111-aaaa-4bbb-cccc-dddddddd0001',
        'name': order['box_name'],
        'description':
            'Выпечка и десерты, приготовленные сегодня. Состав — сюрприз!',
        'original_price': (order['price'] as int) * 2.5,
        'discounted_price': order['price'],
        'image_url':
            'https://images.berezhok.ru/boxes/evening-surprise.jpg',
      },
      if (!isPending)
        'payment': {
          'method': 'card',
          'status': 'paid',
          'paid_at': order['created_at'],
        },
    };
  }
}
