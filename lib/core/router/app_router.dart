import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:berezhok/core/router/stub_pages.dart';
import 'package:berezhok/features/auth/presentation/pages/phone_input_page.dart';
import 'package:berezhok/features/auth/presentation/pages/code_verification_page.dart';
import 'package:berezhok/features/auth/providers/auth_providers.dart';
import 'package:berezhok/features/catalog/presentation/pages/catalog_page.dart';
import 'package:berezhok/features/catalog/presentation/pages/location_detail_page.dart';
import 'package:berezhok/features/home/presentation/pages/home_page.dart';
import 'package:berezhok/features/map/presentation/pages/map_page.dart';
import 'package:berezhok/features/orders/presentation/pages/orders_page.dart';
import 'package:berezhok/features/orders/presentation/pages/order_detail_page.dart';
import 'package:berezhok/features/profile/presentation/pages/profile_page.dart';
import 'package:berezhok/core/services/deep_link_service.dart';

// Route paths as constants
abstract final class AppRoutes {
  static const splash = '/';
  static const authPhone = '/auth/phone';
  static const authCode = '/auth/code';
  static const map = '/map';
  static const catalog = '/catalog';
  static const locationDetail = '/catalog/:id';
  static const orders = '/orders';
  static const orderDetail = '/orders/:id';
  static const profile = '/profile';
}

final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  final service = DeepLinkService();
  ref.onDispose(service.dispose);
  return service;
});

final routerProvider = Provider<GoRouter>((ref) {
  // Listen authState and trigger router refresh without recreating GoRouter
  final notifier = _GoRouterAuthNotifier(ref);

  ref.onDispose(notifier.dispose);

  final initialAuth = ref.read(authStateProvider);
  final initialLoggedIn = initialAuth.valueOrNull != null;

  final router = GoRouter(
    initialLocation: initialLoggedIn ? AppRoutes.map : AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isSplash = state.matchedLocation == '/';

      if (isSplash) {
        return isLoggedIn ? AppRoutes.map : AppRoutes.authPhone;
      }
      if (!isLoggedIn && !isAuthRoute) return AppRoutes.authPhone;
      if (isLoggedIn && isAuthRoute) return AppRoutes.map;
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.authPhone,
        builder: (_, __) => const PhoneInputPage(),
      ),
      GoRoute(
        path: AppRoutes.authCode,
        builder: (_, state) {
          final phone = state.uri.queryParameters['phone'] ?? '';
          return CodeVerificationPage(phone: phone);
        },
      ),

      // Shell route for bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomePage(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.map,
                builder: (_, __) => const MapPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.catalog,
                builder: (_, __) => const CatalogPage(),
              ),
              GoRoute(
                path: AppRoutes.locationDetail,
                builder: (_, state) {
                  return LocationDetailPage(
                    locationId: state.pathParameters['id']!,
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.orders,
                builder: (_, __) => const OrdersPage(),
              ),
              GoRoute(
                path: AppRoutes.orderDetail,
                builder: (_, state) {
                  return OrderDetailPage(
                    orderId: state.pathParameters['id']!,
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (_, __) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  // Initialize deep link service with the router
  final deepLinkService = ref.read(deepLinkServiceProvider);
  deepLinkService.init(router);

  return router;
});

class _GoRouterAuthNotifier extends ChangeNotifier {
  _GoRouterAuthNotifier(Ref ref) {
    ref.listen(authStateProvider, (prev, next) {
      notifyListeners();
    });
  }

  void notify() {
    notifyListeners();
  }
}
