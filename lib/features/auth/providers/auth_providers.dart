import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:berezhok/core/api/api_providers.dart';
import 'package:berezhok/features/auth/data/repositories/auth_repository.dart';
import 'package:berezhok/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:berezhok/features/auth/data/repositories/api_auth_repository.dart';
import 'package:berezhok/features/auth/domain/user.dart';

// Repository provider — switches between Mock and API based on env variable
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final useMock = ref.watch(useMockApiProvider);

  if (useMock) {
    return MockAuthRepository();
  } else {
    return ApiAuthRepository(
      apiClient: ref.watch(apiClientProvider),
    );
  }
});

// Auth state — holds the current user (null = not logged in)
final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, User?>(() => AuthNotifier());

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    // On startup, check if user is already logged in
    final repo = ref.read(authRepositoryProvider);
    return repo.getCurrentUser();
  }

  Future<void> sendCode(String phone) async {
    final repo = ref.read(authRepositoryProvider);
    await repo.sendCode(phone);
  }

  Future<void> verifyCode(String phone, String code) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      return repo.verifyCode(phone, code);
    });
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = const AsyncData(null);
  }

  Future<void> updateName(String name) async {
    final repo = ref.read(authRepositoryProvider);
    if (repo is MockAuthRepository) {
      final updated = await repo.updateUserName(name);
      if (updated != null) {
        state = AsyncData(updated);
      }
    }
  }
}

// Convenience providers
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).valueOrNull != null;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});
