import 'package:berezhok/core/api/api_client.dart';
import 'package:berezhok/core/api/api_endpoints.dart';
import 'package:berezhok/features/catalog/domain/location.dart';
import 'package:berezhok/features/catalog/domain/review.dart';
import 'location_repository.dart';

class ApiLocationRepository implements LocationRepository {
  final ApiClient _apiClient;

  ApiLocationRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<List<FoodLocation>> getLocations({
    required double lat,
    required double lng,
    double radius = 5000,
    String? category,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _apiClient.getPaginated<FoodLocation>(
      ApiEndpoints.locations,
      fromJson: FoodLocation.fromJson,
      queryParameters: {
        'lat': lat,
        'lng': lng,
        'radius': radius,
        if (category != null) 'category': category,
        'limit': limit,
        'offset': offset,
      },
    );

    if (!response.success) {
      throw Exception(response.error?.message ?? 'Failed to fetch locations');
    }

    return response.items;
  }

  @override
  Future<FoodLocation> getLocationDetail(String id) async {
    final response = await _apiClient.get<FoodLocation>(
      ApiEndpoints.locationDetail(id),
      fromJson: FoodLocation.fromJson,
    );

    if (!response.success || response.data == null) {
      throw Exception(
          response.error?.message ?? 'Failed to fetch location detail');
    }

    return response.data!;
  }

  @override
  Future<List<Review>> getLocationReviews(
    String locationId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _apiClient.getPaginated<Review>(
      ApiEndpoints.locationReviews(locationId),
      fromJson: Review.fromJson,
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
    );

    if (!response.success) {
      throw Exception(response.error?.message ?? 'Failed to fetch reviews');
    }

    return response.items;
  }
}
