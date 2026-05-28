import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

class DeepLinkService {
  final AppLinks _appLinks = AppLinks();
  GoRouter? _router;
  StreamSubscription<Uri>? _linkSubscription;

  /// Initialize deep link handling.
  /// Must be called after GoRouter is created.
  void init(GoRouter router) {
    _router = router;
    _handleInitialLink();
    _handleIncomingLinks();
  }

  /// Handle the initial link when the app is opened from a terminated state.
  Future<void> _handleInitialLink() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _processUri(initialUri);
      }
    } catch (e) {
      debugPrint('Failed to get initial app link: $e');
    }
  }

  /// Handle incoming links when the app is already running.
  void _handleIncomingLinks() {
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) => _processUri(uri),
      onError: (err) {
        debugPrint('Error receiving deep link: $err');
      },
    );
  }

  /// Process a deep link URI.
  void _processUri(Uri uri) {
    debugPrint('Received deep link: $uri');
    final router = _router;
    if (router == null) {
      debugPrint('Router not initialized, cannot navigate');
      return;
    }

    // For custom-scheme URIs (berezhok://orders/123):
    //   uri.host = 'orders', uri.path = '/123'
    // For https/http URIs: uri.host = 'berezhok.ru', uri.path = '/orders/123'
    final path = uri.host.isNotEmpty ? '/${uri.host}${uri.path}' : uri.path;
    if (path.isNotEmpty && path != '/') {
      router.go(path);
    } else {
      debugPrint('Deep link path is empty or root');
    }
  }

  /// Dispose resources.
  void dispose() {
    _linkSubscription?.cancel();
  }
}