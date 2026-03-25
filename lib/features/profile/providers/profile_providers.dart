import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:berezhok/core/api/api_providers.dart';
import 'package:berezhok/features/profile/data/repositories/profile_repository.dart';
import 'package:berezhok/features/profile/data/repositories/mock_profile_repository.dart';
import 'package:berezhok/features/profile/data/repositories/api_profile_repository.dart';
import 'package:berezhok/features/profile/domain/user_profile.dart';

/// Repository provider — switches between Mock and API based on env variable
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final useMock = ref.watch(useMockApiProvider);

  if (useMock) {
    return MockProfileRepository();
  } else {
    return ApiProfileRepository(ref.watch(apiClientProvider));
  }
});

/// User profile state.
final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, UserProfile>(ProfileNotifier.new);

class ProfileNotifier extends AsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() async {
    final repo = ref.read(profileRepositoryProvider);
    return repo.getProfile();
  }

  Future<void> updateProfile({
    String? name,
  }) async {
    final repo = ref.read(profileRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => repo.updateProfile(
          name: name,
        ));
  }

  Future<void> refresh() async {
    final repo = ref.read(profileRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => repo.getProfile());
  }
}
