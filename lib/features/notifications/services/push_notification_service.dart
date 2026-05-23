import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'package:berezhok/features/notifications/data/repositories/push_notification_repository.dart';
import 'package:berezhok/features/notifications/services/push_notification_router.dart';

class PushNotificationService {
  final bool _isEnabled;
  final PushNotificationRepository _repository;
  final FirebaseMessaging? _messaging;

  GoRouter? _router;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  bool _listenersConfigured = false;
  String? _registeredToken;

  PushNotificationService({
    required bool isEnabled,
    required PushNotificationRepository repository,
    FirebaseMessaging? messaging,
  }) : _isEnabled = isEnabled,
       _repository = repository,
       _messaging = isEnabled ? messaging ?? FirebaseMessaging.instance : null;

  void attachRouter(GoRouter router) {
    _router = router;
    _configureMessageListeners();
  }

  Future<void> start() async {
    if (!_isEnabled || _messaging == null) return;

    final permission = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (!_hasNotificationPermission(permission.authorizationStatus)) {
      debugPrint('Push notifications permission was not granted');
      return;
    }

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await _messaging.getToken();
    if (token != null) {
      await _registerToken(token);
    }

    _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen(
      (token) => unawaited(_registerToken(token)),
      onError: (error) {
        debugPrint('Failed to refresh push token: $error');
      },
    );
  }

  Future<void> stopLocal() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _registeredToken = null;
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _openedAppSubscription?.cancel();
    await _foregroundSubscription?.cancel();
  }

  void _configureMessageListeners() {
    if (!_isEnabled || _messaging == null || _listenersConfigured) return;

    _listenersConfigured = true;
    unawaited(_handleInitialMessage());

    _openedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _handleMessageOpened,
      onError: (error) {
        debugPrint('Failed to handle opened push notification: $error');
      },
    );

    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
      onError: (error) {
        debugPrint('Failed to handle foreground push notification: $error');
      },
    );
  }

  Future<void> _handleInitialMessage() async {
    final message = await _messaging?.getInitialMessage();
    if (message != null) {
      _handleMessageOpened(message);
    }
  }

  void _handleMessageOpened(RemoteMessage message) {
    final path = PushNotificationRouter.pathFromData(message.data);
    if (path == null) {
      debugPrint('Push notification has no supported route: ${message.data}');
      return;
    }
    _router?.go(path);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground push notification received: ${message.data}');
  }

  Future<void> _registerToken(String token) async {
    if (_registeredToken == token) return;

    final platform = _currentPlatform();
    if (platform == null) {
      debugPrint('Push token registration skipped for unsupported platform');
      return;
    }

    try {
      await _repository.registerToken(token: token, platform: platform);
      _registeredToken = token;
    } catch (error) {
      debugPrint('Failed to register push token: $error');
    }
  }

  bool _hasNotificationPermission(AuthorizationStatus status) {
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  String? _currentPlatform() {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => null,
    };
  }
}
