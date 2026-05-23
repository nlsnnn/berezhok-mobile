import 'push_notification_repository.dart';

class MockPushNotificationRepository implements PushNotificationRepository {
  String? lastToken;
  String? lastPlatform;

  @override
  Future<void> registerToken({
    required String token,
    required String platform,
  }) async {
    lastToken = token;
    lastPlatform = platform;
  }
}
