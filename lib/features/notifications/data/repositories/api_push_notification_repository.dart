import 'package:berezhok/core/api/api_client.dart';
import 'package:berezhok/core/api/api_endpoints.dart';
import 'push_notification_repository.dart';

class ApiPushNotificationRepository implements PushNotificationRepository {
  final ApiClient _apiClient;

  ApiPushNotificationRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  @override
  Future<void> registerToken({
    required String token,
    required String platform,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.registerPushToken,
      fromJson: (json) => json,
      data: {'token': token, 'platform': platform},
    );

    if (!response.success) {
      throw Exception(
        response.error?.message ?? 'Failed to register push token',
      );
    }
  }
}
