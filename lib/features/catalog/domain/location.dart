import 'location_category.dart';
import 'surprise_box.dart';

class LocationPin {
  final String code;
  final String nameRu;

  const LocationPin({required this.code, required this.nameRu});

  factory LocationPin.fromJson(Map<String, dynamic> json) => LocationPin(
        code: json['code'] as String,
        nameRu: json['name_ru'] as String,
      );

  Map<String, dynamic> toJson() => {'code': code, 'name_ru': nameRu};
}

class FoodLocation {
  final String id;
  final String name;
  final LocationCategory category;
  final String address;
  final double latitude;
  final double longitude;
  final double? distance;
  final LocationRating? rating;
  final String? logoUrl;
  final String? coverImageUrl;
  final List<String> galleryUrls;
  final Map<String, String>? workingHours;
  final String? phone;
  final int activeBoxesCount;
  final List<SurpriseBox> activeBoxes;
  final List<LocationPin> pins;

  const FoodLocation({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.distance,
    this.rating,
    this.logoUrl,
    this.coverImageUrl,
    this.galleryUrls = const [],
    this.workingHours,
    this.phone,
    this.activeBoxesCount = 0,
    this.activeBoxes = const [],
    this.pins = const [],
  });

  factory FoodLocation.fromJson(Map<String, dynamic> json) {
    // Parse coordinates object from API: {lat, lng}
    final coords = json['coordinates'] as Map<String, dynamic>?;
    final lat = coords != null
        ? (coords['lat'] as num).toDouble()
        : (json['latitude'] as num?)?.toDouble() ?? 0.0;
    final lng = coords != null
        ? (coords['lng'] as num).toDouble()
        : (json['longitude'] as num?)?.toDouble() ?? 0.0;

    return FoodLocation(
      id: json['id'] as String,
      name: json['name'] as String,
      category: LocationCategory.fromJson(
          json['category'] as Map<String, dynamic>),
      address: json['address'] as String,
      latitude: lat,
      longitude: lng,
      distance: (json['distance'] as num?)?.toDouble(),
      rating: json['rating'] != null
          ? LocationRating.fromJson(json['rating'] as Map<String, dynamic>)
          : null,
      logoUrl: json['logo_url'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      galleryUrls: (json['gallery'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      workingHours: (json['working_hours'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(_normalizeWeekdayKey(k), v as String)),
      phone: json['phone'] as String?,
      activeBoxesCount: (json['active_boxes_count'] as num?)?.toInt() ??
          ((json['active_boxes'] as List<dynamic>?)?.length ?? 0),
      activeBoxes: (json['active_boxes'] as List<dynamic>?)
              ?.map((e) =>
                  SurpriseBox.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      pins: (json['pins'] as List<dynamic>?)
              ?.map((e) => LocationPin.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.toJson(),
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        if (distance != null) 'distance': distance,
        if (rating != null) 'rating': rating!.toJson(),
        if (logoUrl != null) 'logo_url': logoUrl,
        if (coverImageUrl != null) 'cover_image_url': coverImageUrl,
        'gallery_urls': galleryUrls,
        if (workingHours != null) 'working_hours': workingHours,
        if (phone != null) 'phone': phone,
        'active_boxes_count': activeBoxesCount,
        if (pins.isNotEmpty) 'pins': pins.map((p) => p.toJson()).toList(),
      };

  @override
  String toString() => 'FoodLocation(id: $id, name: $name, address: $address)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodLocation &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class LocationRating {
  final double average;
  final int totalReviews;
  final Map<int, int>? distribution;

  const LocationRating({
    required this.average,
    required this.totalReviews,
    this.distribution,
  });

  factory LocationRating.fromJson(Map<String, dynamic> json) => LocationRating(
        average: (json['average'] as num).toDouble(),
        totalReviews: (json['total_reviews'] as num).toInt(),
        distribution: (json['distribution'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(int.parse(k), (v as num).toInt())),
      );

  Map<String, dynamic> toJson() => {
        'average': average,
        'total_reviews': totalReviews,
        if (distribution != null)
          'distribution':
              distribution!.map((k, v) => MapEntry(k.toString(), v)),
      };

  @override
  String toString() =>
      'LocationRating(average: $average, totalReviews: $totalReviews)';
}

const _weekdayKeyMap = <String, String>{
  'mon': 'mon', 'monday': 'mon', '1': 'mon',
  'tue': 'tue', 'tuesday': 'tue', '2': 'tue',
  'wed': 'wed', 'wednesday': 'wed', '3': 'wed',
  'thu': 'thu', 'thursday': 'thu', '4': 'thu',
  'fri': 'fri', 'friday': 'fri', '5': 'fri',
  'sat': 'sat', 'saturday': 'sat', '6': 'sat',
  'sun': 'sun', 'sunday': 'sun', '7': 'sun', '0': 'sun',
};

String _normalizeWeekdayKey(String key) =>
    _weekdayKeyMap[key.toLowerCase()] ?? key;
