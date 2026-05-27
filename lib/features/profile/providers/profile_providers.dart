import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:berezhok/core/api/api_providers.dart';
import 'package:berezhok/features/profile/data/repositories/profile_repository.dart';
import 'package:berezhok/features/profile/data/repositories/mock_profile_repository.dart';
import 'package:berezhok/features/profile/data/repositories/api_profile_repository.dart';
import 'package:berezhok/features/profile/data/repositories/eco_stats_repository.dart';
import 'package:berezhok/features/profile/data/repositories/mock_eco_stats_repository.dart';
import 'package:berezhok/features/profile/data/repositories/api_eco_stats_repository.dart';
import 'package:berezhok/features/profile/domain/user_profile.dart';
import 'package:berezhok/features/profile/domain/eco_stats.dart';

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

// ---------------------------------------------------------------------------
// Eco-stats
// ---------------------------------------------------------------------------

final ecoStatsRepositoryProvider = Provider<EcoStatsRepository>((ref) {
  final useMock = ref.watch(useMockApiProvider);
  if (useMock) {
    return MockEcoStatsRepository();
  } else {
    return ApiEcoStatsRepository(ref.watch(apiClientProvider));
  }
});

final ecoStatsProvider =
    AsyncNotifierProvider<EcoStatsNotifier, EcoStats>(EcoStatsNotifier.new);

class EcoStatsNotifier extends AsyncNotifier<EcoStats> {
  @override
  Future<EcoStats> build() async {
    final repo = ref.read(ecoStatsRepositoryProvider);
    return repo.getEcoStats();
  }

  Future<void> refresh() async {
    final repo = ref.read(ecoStatsRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => repo.getEcoStats());
  }
}
