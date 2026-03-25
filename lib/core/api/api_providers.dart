import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

import 'api_client.dart';

/// Base URL for API requests (from .env)
final baseUrlProvider = Provider<String>((ref) {
  return dotenv.get('API_BASE_URL', fallback: 'http://localhost:8080/v1');
});

/// Flag to determine whether to use mock API or real API (from .env)
final useMockApiProvider = Provider<bool>((ref) {
  return dotenv.get('USE_MOCK_API', fallback: 'false') == 'true';
});

/// Environment name (dev/prod) for conditional logging
final environmentProvider = Provider<String>((ref) {
  return dotenv.get('FLUTTER_ENV', fallback: 'dev');
});

/// Auth token provider that reads from secure storage
/// This is used by ApiClient to inject the Bearer token
final authTokenProvider = Provider<Future<String?> Function()>((ref) {
  const storage = FlutterSecureStorage();
  return () => storage.read(key: 'auth_token');
});

/// Global ApiClient instance configured with base URL and auth token provider
final apiClientProvider = Provider<ApiClient>((ref) {
  final baseUrl = ref.watch(baseUrlProvider);
  final environment = ref.watch(environmentProvider);
  final tokenProvider = ref.watch(authTokenProvider);

  return ApiClient(
    baseUrl: baseUrl,
    authTokenProvider: tokenProvider,
    extraInterceptors: [
      // Add logging in dev mode
      if (environment == 'dev')
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: false,
          error: true,
        ),
    ],
  );
});
