import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:berezhok/core/router/stub_pages.dart';
import 'package:berezhok/features/auth/presentation/pages/phone_input_page.dart';
import 'package:berezhok/features/auth/presentation/pages/code_verification_page.dart';
import 'package:berezhok/features/auth/providers/auth_providers.dart';
import 'package:berezhok/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:berezhok/features/onboarding/providers/onboarding_providers.dart';
import 'package:berezhok/features/catalog/presentation/pages/catalog_page.dart';
import 'package:berezhok/features/catalog/presentation/pages/location_detail_page.dart';
import 'package:berezhok/features/home/presentation/pages/home_page.dart';
import 'package:berezhok/features/map/presentation/pages/map_page.dart';
import 'package:berezhok/features/orders/presentation/pages/orders_page.dart';
import 'package:berezhok/features/orders/presentation/pages/order_detail_page.dart';
import 'package:berezhok/features/chat/presentation/pages/chat_page.dart';
import 'package:berezhok/features/profile/presentation/pages/profile_page.dart';
import 'package:berezhok/core/services/deep_link_service.dart';
import 'package:berezhok/features/notifications/providers/push_notification_providers.dart';

// Route paths as constants
abstract final class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const authPhone = '/auth/phone';
  static const authCode = '/auth/code';
  static const map = '/map';
  static const catalog = '/catalog';
  static const locationDetail = '/catalog/:id';
  static const orders = '/orders';
  static const orderDetail = '/orders/:id';
  static const orderChat = '/orders/:id/chat';
  static const profile = '/profile';
}

final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  final service = DeepLinkService();
  ref.onDispose(service.dispose);
  return service;
});

final routerProvider = Provider<GoRouter>((ref) {
  // Listen authState and trigger router refresh without recreating GoRouter
  final notifier = _GoRouterStateNotifier(ref);

  ref.onDispose(notifier.dispose);

  final initialAuth = ref.read(authStateProvider);
  final initialLoggedIn = initialAuth.valueOrNull != null;

  final router = GoRouter(
    initialLocation: initialLoggedIn ? AppRoutes.map : AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final onboardingState = ref.read(onboardingStateProvider);

      final isAuthResolved = authState.hasValue || authState.hasError;
      final isOnboardingResolved =
          onboardingState.hasValue || onboardingState.hasError;

      final isLoggedIn = authState.valueOrNull != null;
      final isOnboardingCompleted = onboardingState.valueOrNull ?? false;

      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isSplash = state.matchedLocation == '/';
      final isOnboardingRoute = state.matchedLocation == AppRoutes.onboarding;

      if (!isAuthResolved || !isOnboardingResolved) {
        return isSplash ? null : AppRoutes.splash;
      }

      if (!isOnboardingCompleted && !isOnboardingRoute) {
        return AppRoutes.onboarding;
      }

      if (isOnboardingCompleted && isOnboardingRoute) {
        return isLoggedIn ? AppRoutes.map : AppRoutes.authPhone;
      }

      if (isSplash) {
        return isLoggedIn ? AppRoutes.map : AppRoutes.authPhone;
      }

      if (!isLoggedIn && !isAuthRoute && !isOnboardingRoute) {
        return AppRoutes.authPhone;
      }
      if (isLoggedIn && isAuthRoute) return AppRoutes.map;

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashPage()),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.authPhone,
        builder: (_, _) => const PhoneInputPage(),
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
        builder: (_, _, navigationShell) =>
            HomePage(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: AppRoutes.map, builder: (_, _) => const MapPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.catalog,
                builder: (_, _) => const CatalogPage(),
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
                builder: (_, _) => const OrdersPage(),
              ),
              GoRoute(
                path: AppRoutes.orderChat,
                builder: (_, state) {
                  return ChatPage(orderId: state.pathParameters['id']!);
                },
              ),
              GoRoute(
                path: AppRoutes.orderDetail,
                builder: (_, state) {
                  return OrderDetailPage(orderId: state.pathParameters['id']!);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (_, _) => const ProfilePage(),
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

  final pushNotificationService = ref.read(pushNotificationServiceProvider);
  pushNotificationService.attachRouter(router);

  return router;
});

class _GoRouterStateNotifier extends ChangeNotifier {
  _GoRouterStateNotifier(Ref ref) {
    ref.listen(authStateProvider, (prev, next) {
      notifyListeners();
    });

    ref.listen(onboardingStateProvider, (prev, next) {
      notifyListeners();
    });
  }

  void notify() {
    notifyListeners();
  }
}
