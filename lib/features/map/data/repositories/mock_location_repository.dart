import 'package:berezhok/features/catalog/domain/location.dart';
import 'package:berezhok/features/catalog/domain/location_category.dart';
import 'package:berezhok/features/catalog/domain/review.dart';

import 'location_repository.dart';

class MockLocationRepository implements LocationRepository {
  @override
  Future<List<FoodLocation>> getLocations({
    required double lat,
    required double lng,
    double radius = 5000,
    String? category,
    int limit = 20,
    int offset = 0,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    var results = List<FoodLocation>.from(_mockLocations);

    if (category != null) {
      results = results.where((l) => l.category.code == category).toList();
    }

    // Sort by distance
    results.sort((a, b) =>
        (a.distance ?? double.infinity).compareTo(b.distance ?? double.infinity));

    return results.skip(offset).take(limit).toList();
  }

  @override
  Future<FoodLocation> getLocationDetail(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final location = _mockLocations.firstWhere(
      (l) => l.id == id,
      orElse: () => throw Exception('Location not found: $id'),
    );

    // Return enriched version with working hours, phone, gallery
    return FoodLocation(
      id: location.id,
      name: location.name,
      category: location.category,
      address: location.address,
      latitude: location.latitude,
      longitude: location.longitude,
      distance: location.distance,
      rating: location.rating,
      activeBoxesCount: location.activeBoxesCount,
      workingHours: _mockWorkingHours[location.id] ?? _defaultWorkingHours,
      phone: _mockPhones[location.id] ?? '+7 (495) 123-45-67',
      galleryUrls: const [],
    );
  }

  @override
  Future<List<Review>> getLocationReviews(
    String locationId, {
    int limit = 20,
    int offset = 0,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _mockReviews.skip(offset).take(limit).toList();
  }
}

// ---------------------------------------------------------------------------
// Mock data
// ---------------------------------------------------------------------------

const _bakery = LocationCategory(code: 'bakery', name: 'Пекарня');
const _cafe = LocationCategory(code: 'cafe', name: 'Кафе');
const _restaurant = LocationCategory(code: 'restaurant', name: 'Ресторан');
const _grocery = LocationCategory(code: 'grocery', name: 'Магазин');
const _hotel = LocationCategory(code: 'hotel', name: 'Отель');

final _mockLocations = <FoodLocation>[
  // Bakeries
  const FoodLocation(
    id: 'loc_1',
    name: 'Пекарня "Хлебница"',
    category: _bakery,
    address: 'ул. Арбат, 12',
    latitude: 55.7520,
    longitude: 37.5900,
    distance: 450,
    rating: LocationRating(average: 4.7, totalReviews: 89),
    activeBoxesCount: 3,
  ),
  const FoodLocation(
    id: 'loc_2',
    name: 'Булочная Ф. Вольчека',
    category: _bakery,
    address: 'ул. Покровка, 19',
    latitude: 55.7610,
    longitude: 37.6500,
    distance: 1200,
    rating: LocationRating(average: 4.3, totalReviews: 156),
    activeBoxesCount: 2,
  ),

  // Cafes
  const FoodLocation(
    id: 'loc_3',
    name: 'Кофейня "Дабл Би"',
    category: _cafe,
    address: 'Мясницкая ул., 24/7с1',
    latitude: 55.7640,
    longitude: 37.6370,
    distance: 800,
    rating: LocationRating(average: 4.5, totalReviews: 210),
    activeBoxesCount: 1,
  ),
  const FoodLocation(
    id: 'loc_4',
    name: 'Кафе "Му-Му"',
    category: _cafe,
    address: 'ул. Тверская, 24',
    latitude: 55.7680,
    longitude: 37.6040,
    distance: 950,
    rating: LocationRating(average: 4.1, totalReviews: 342),
    activeBoxesCount: 5,
  ),
  const FoodLocation(
    id: 'loc_5',
    name: 'Surf Coffee',
    category: _cafe,
    address: 'Чистопрудный б-р, 12с2',
    latitude: 55.7630,
    longitude: 37.6430,
    distance: 1100,
    rating: LocationRating(average: 4.6, totalReviews: 178),
    activeBoxesCount: 2,
  ),

  // Restaurants
  const FoodLocation(
    id: 'loc_6',
    name: 'Ресторан "Марукамэ"',
    category: _restaurant,
    address: 'ул. Петровка, 21/2',
    latitude: 55.7660,
    longitude: 37.6150,
    distance: 600,
    rating: LocationRating(average: 4.4, totalReviews: 520),
    activeBoxesCount: 2,
  ),
  const FoodLocation(
    id: 'loc_7',
    name: 'Теремок',
    category: _restaurant,
    address: 'Новый Арбат, 15',
    latitude: 55.7530,
    longitude: 37.5850,
    distance: 750,
    rating: LocationRating(average: 4.0, totalReviews: 890),
    activeBoxesCount: 4,
  ),
  const FoodLocation(
    id: 'loc_8',
    name: 'Грабли',
    category: _restaurant,
    address: 'ул. Пятницкая, 27',
    latitude: 55.7420,
    longitude: 37.6290,
    distance: 1800,
    rating: LocationRating(average: 4.2, totalReviews: 415),
    activeBoxesCount: 3,
  ),

  // Grocery
  const FoodLocation(
    id: 'loc_9',
    name: 'ВкусВилл',
    category: _grocery,
    address: 'ул. Маросейка, 6/8',
    latitude: 55.7580,
    longitude: 37.6360,
    distance: 350,
    rating: LocationRating(average: 4.8, totalReviews: 1230),
    activeBoxesCount: 7,
  ),
  const FoodLocation(
    id: 'loc_10',
    name: 'Азбука Вкуса',
    category: _grocery,
    address: 'Ленинградский пр-т, 10',
    latitude: 55.7760,
    longitude: 37.5870,
    distance: 2100,
    rating: LocationRating(average: 4.5, totalReviews: 670),
    activeBoxesCount: 4,
  ),
  const FoodLocation(
    id: 'loc_11',
    name: 'Перекрёсток',
    category: _grocery,
    address: 'Садовая-Кудринская, 3',
    latitude: 55.7670,
    longitude: 37.5920,
    distance: 1500,
    rating: LocationRating(average: 4.0, totalReviews: 980),
    activeBoxesCount: 6,
  ),

  // Hotel
  const FoodLocation(
    id: 'loc_12',
    name: 'Отель "Метрополь"',
    category: _hotel,
    address: 'Театральный проезд, 2',
    latitude: 55.7590,
    longitude: 37.6210,
    distance: 500,
    rating: LocationRating(average: 4.9, totalReviews: 45),
    activeBoxesCount: 1,
  ),
];

final _defaultWorkingHours = const {
  'mon': '08:00–22:00',
  'tue': '08:00–22:00',
  'wed': '08:00–22:00',
  'thu': '08:00–22:00',
  'fri': '08:00–23:00',
  'sat': '09:00–23:00',
  'sun': '09:00–21:00',
};

final _mockWorkingHours = <String, Map<String, String>>{
  'loc_12': const {
    'mon': '07:00–23:00',
    'tue': '07:00–23:00',
    'wed': '07:00–23:00',
    'thu': '07:00–23:00',
    'fri': '07:00–00:00',
    'sat': '07:00–00:00',
    'sun': '07:00–22:00',
  },
  'loc_9': const {
    'mon': '07:00–23:00',
    'tue': '07:00–23:00',
    'wed': '07:00–23:00',
    'thu': '07:00–23:00',
    'fri': '07:00–23:00',
    'sat': '08:00–23:00',
    'sun': '08:00–22:00',
  },
};

final _mockPhones = <String, String>{
  'loc_1': '+7 (495) 697-12-34',
  'loc_3': '+7 (495) 621-33-44',
  'loc_6': '+7 (495) 694-55-66',
  'loc_9': '+7 (495) 623-77-88',
  'loc_12': '+7 (499) 501-78-00',
};

final _mockReviews = <Review>[
  Review(
    id: 'rev_1',
    rating: 5,
    comment: 'Отличный набор! Получили свежие круассаны и хлеб, всё очень вкусно.',
    userName: 'Анна К.',
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
  ),
  Review(
    id: 'rev_2',
    rating: 4,
    comment: 'Хорошее соотношение цены и качества. Забрали большой пакет выпечки.',
    userName: 'Дмитрий П.',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  Review(
    id: 'rev_3',
    rating: 5,
    comment: 'Супер! Три порции салатов и десерт — всё свежее. Буду брать ещё.',
    userName: 'Мария С.',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
  Review(
    id: 'rev_4',
    rating: 3,
    comment: 'Нормально, но набор мог бы быть разнообразнее.',
    userName: 'Алексей Н.',
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
  ),
  Review(
    id: 'rev_5',
    rating: 5,
    comment: 'Лучшее приложение для спасения еды! Забирал уже 5 раз.',
    userName: 'Елена В.',
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
  ),
  Review(
    id: 'rev_6',
    rating: 4,
    comment: 'Удобное время получения, персонал приветливый.',
    userName: 'Иван Ч.',
    createdAt: DateTime.now().subtract(const Duration(days: 7)),
  ),
  Review(
    id: 'rev_7',
    rating: 5,
    comment: 'Потрясающе! Целый торт за 200 рублей — не верила своим глазам.',
    userName: 'Ольга Р.',
    createdAt: DateTime.now().subtract(const Duration(days: 10)),
  ),
];
