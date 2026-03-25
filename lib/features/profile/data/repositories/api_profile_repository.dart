import 'package:berezhok/core/api/api_client.dart';
import 'package:berezhok/core/api/api_endpoints.dart';
import 'package:berezhok/features/profile/domain/user_profile.dart';
import 'profile_repository.dart';

class ApiProfileRepository implements ProfileRepository {
  final ApiClient _client;

  ApiProfileRepository(this._client);

  @override
  Future<UserProfile> getProfile() async {
    final response = await _client.get<UserProfile>(
      ApiEndpoints.profile,
      fromJson: UserProfile.fromJson,
    );

    if (!response.success || response.data == null) {
      throw Exception(response.error?.message ?? 'Failed to fetch profile');
    }

    return response.data!;
  }

  @override
  Future<UserProfile> updateProfile({
    String? name,
  }) async {
    final response = await _client.patch<UserProfile>(
      ApiEndpoints.updateProfile,
      fromJson: UserProfile.fromJson,
      data: {
        if (name != null && name.isNotEmpty) 'name': name,
      },
    );

    if (!response.success || response.data == null) {
      throw Exception(response.error?.message ?? 'Failed to update profile');
    }

    return response.data!;
  }
}
