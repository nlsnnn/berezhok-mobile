import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'package:berezhok/features/map/data/services/user_location_service.dart';

final userLocationServiceProvider = Provider<UserLocationService>((ref) {
  return UserLocationService();
});

/// Provides the current user location result (permission + position).
final userLocationProvider =
    AsyncNotifierProvider<UserLocationNotifier, UserLocationResult>(
  UserLocationNotifier.new,
);

class UserLocationNotifier extends AsyncNotifier<UserLocationResult> {
  @override
  Future<UserLocationResult> build() async {
    final service = ref.read(userLocationServiceProvider);
    return service.getCurrentPosition();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(userLocationServiceProvider).getCurrentPosition(),
    );
  }

  Future<void> openSettings() async {
    await ref.read(userLocationServiceProvider).openSettings();
  }
}

/// Convenience: exposes only the [Position] (null when denied / unavailable).
final userPositionProvider = Provider<Position?>((ref) {
  return ref.watch(userLocationProvider).valueOrNull?.position;
});
