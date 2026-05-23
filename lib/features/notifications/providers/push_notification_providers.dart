import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:berezhok/core/api/api_providers.dart';
import 'package:berezhok/features/notifications/data/repositories/api_push_notification_repository.dart';
import 'package:berezhok/features/notifications/data/repositories/mock_push_notification_repository.dart';
import 'package:berezhok/features/notifications/data/repositories/push_notification_repository.dart';
import 'package:berezhok/features/notifications/services/push_notification_service.dart';

final pushNotificationsEnabledProvider = Provider<bool>((ref) {
  return dotenv.get('ENABLE_PUSH_NOTIFICATIONS', fallback: 'false') == 'true';
});

final firebaseMessagingInitializedProvider = Provider<bool>((ref) => false);

final pushNotificationRepositoryProvider = Provider<PushNotificationRepository>(
  (ref) {
    final useMock = ref.watch(useMockApiProvider);
    if (useMock) return MockPushNotificationRepository();
    return ApiPushNotificationRepository(
      apiClient: ref.watch(apiClientProvider),
    );
  },
);

final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  final service = PushNotificationService(
    isEnabled:
        ref.watch(pushNotificationsEnabledProvider) &&
        ref.watch(firebaseMessagingInitializedProvider),
    repository: ref.watch(pushNotificationRepositoryProvider),
  );

  ref.onDispose(() {
    unawaited(service.dispose());
  });

  return service;
});
