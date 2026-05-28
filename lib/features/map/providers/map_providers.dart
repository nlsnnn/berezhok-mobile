import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'package:berezhok/core/api/api_providers.dart';
import 'package:berezhok/features/catalog/domain/location.dart';
import 'package:berezhok/features/catalog/domain/review.dart';
import 'package:berezhok/features/map/data/repositories/location_repository.dart';
import 'package:berezhok/features/map/data/repositories/mock_location_repository.dart';
import 'package:berezhok/features/map/data/repositories/api_location_repository.dart';
import 'package:berezhok/features/map/providers/user_location_provider.dart';

/// Repository provider — switches between Mock and API based on env variable
final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  final useMock = ref.watch(useMockApiProvider);

  if (useMock) {
    return MockLocationRepository();
  } else {
    return ApiLocationRepository(apiClient: ref.watch(apiClientProvider));
  }
});

/// All locations visible on the map, filtered by optional category.
final locationsProvider =
    AsyncNotifierProvider<LocationsNotifier, List<FoodLocation>>(
  LocationsNotifier.new,
);

// Default fallback coordinates (Moscow centre) used when GPS is unavailable.
const _defaultLat = 55.7558;
const _defaultLng = 37.6173;

class LocationsNotifier extends AsyncNotifier<List<FoodLocation>> {
  @override
  Future<List<FoodLocation>> build() async {
    final category = ref.watch(selectedCategoryProvider);
    final locationResult = await ref.watch(userLocationProvider.future);
    final position = locationResult.position;

    final repo = ref.read(locationRepositoryProvider);
    final locations = await repo.getLocations(
      lat: position?.latitude ?? _defaultLat,
      lng: position?.longitude ?? _defaultLng,
      category: category,
    );

    return _withDistances(locations, position);
  }

  Future<void> refresh({double? lat, double? lng, String? category}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final position = ref.read(userPositionProvider);
      final repo = ref.read(locationRepositoryProvider);
      final locations = await repo.getLocations(
        lat: lat ?? position?.latitude ?? _defaultLat,
        lng: lng ?? position?.longitude ?? _defaultLng,
        category: category ?? ref.read(selectedCategoryProvider),
      );
      return _withDistances(locations, position);
    });
  }

  List<FoodLocation> _withDistances(
    List<FoodLocation> locations,
    Position? position,
  ) {
    if (position == null) return locations;
    return locations.map((loc) {
      final meters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        loc.latitude,
        loc.longitude,
      );
      return loc.copyWith(distance: meters);
    }).toList();
  }
}

/// Currently selected category filter chip (null = all).
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

/// Location tapped on the map — drives the preview card.
final selectedMapLocationProvider = StateProvider<FoodLocation?>((ref) => null);

/// Full location detail (with working hours, phone, etc.)
final locationDetailProvider =
    FutureProvider.family<FoodLocation, String>((ref, id) async {
  final repo = ref.read(locationRepositoryProvider);
  return repo.getLocationDetail(id);
});

/// Reviews for a specific location.
final locationReviewsProvider =
    FutureProvider.family<List<Review>, String>((ref, locationId) async {
  final repo = ref.read(locationRepositoryProvider);
  return repo.getLocationReviews(locationId);
});
