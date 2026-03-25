import 'package:berezhok/features/catalog/domain/location.dart';
import 'package:berezhok/features/catalog/domain/review.dart';

abstract class LocationRepository {
  Future<List<FoodLocation>> getLocations({
    required double lat,
    required double lng,
    double radius = 5000,
    String? category,
    int limit = 20,
    int offset = 0,
  });

  Future<FoodLocation> getLocationDetail(String id);

  Future<List<Review>> getLocationReviews(
    String locationId, {
    int limit = 20,
    int offset = 0,
  });
}
