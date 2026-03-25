import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:berezhok/core/api/api_providers.dart';
import 'package:berezhok/features/catalog/domain/location.dart';
import 'package:berezhok/features/catalog/domain/review.dart';
import 'package:berezhok/features/map/data/repositories/location_repository.dart';
import 'package:berezhok/features/map/data/repositories/mock_location_repository.dart';
import 'package:berezhok/features/map/data/repositories/api_location_repository.dart';

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

class LocationsNotifier extends AsyncNotifier<List<FoodLocation>> {
  @override
  Future<List<FoodLocation>> build() async {
    final category = ref.watch(selectedCategoryProvider);
    final repo = ref.read(locationRepositoryProvider);
    return repo.getLocations(
      lat: 55.7558,
      lng: 37.6173,
      category: category,
    );
  }

  Future<void> refresh({double? lat, double? lng, String? category}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      final repo = ref.read(locationRepositoryProvider);
      return repo.getLocations(
        lat: lat ?? 55.7558,
        lng: lng ?? 37.6173,
        category: category ?? ref.read(selectedCategoryProvider),
      );
    });
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
