/// High-level HTTP client that wraps [Dio] and returns typed [ApiResponse]s.
///
/// Usage:
/// ```dart
/// final client = ApiClient(
///   baseUrl: 'https://api.berezhok.ru/v1',
///   authTokenProvider: () async => secureStorage.read('access_token'),
/// );
///
/// final resp = await client.get<UserProfile>(
///   '/customer/profile',
///   fromJson: UserProfile.fromJson,
/// );
/// ```
library;

import 'package:dio/dio.dart';

import 'api_exceptions.dart';
import 'api_response.dart';

/// Callback that returns the current auth token (or null if not logged in).
typedef AuthTokenProvider = Future<String?> Function();

class ApiClient {
  final Dio _dio;

  ApiClient({
    String baseUrl = '',
    AuthTokenProvider? authTokenProvider,
    List<Interceptor> extraInterceptors = const [],
  }) : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(seconds: 15),
            contentType: Headers.jsonContentType,
            responseType: ResponseType.json,
          ),
        ) {
    // Auth interceptor — injects Bearer token when available.
    if (authTokenProvider != null) {
      _dio.interceptors.add(_AuthInterceptor(authTokenProvider));
    }

    // Extra interceptors (e.g. MockInterceptor for dev builds).
    _dio.interceptors.addAll(extraInterceptors);

    // Error interceptor — converts DioExceptions to typed ApiExceptions.
    _dio.interceptors.add(_ErrorInterceptor());
  }

  /// Expose the underlying [Dio] instance for advanced configuration.
  Dio get dio => _dio;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  Future<ApiResponse<T>> get<T>(
    String path, {
    required T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      path,
      queryParameters: queryParameters,
    );
    return ApiResponse.fromJson(response.data!, fromJson);
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    required T Function(Map<String, dynamic>) fromJson,
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      path,
      data: data,
      queryParameters: queryParameters,
    );
    return ApiResponse.fromJson(response.data!, fromJson);
  }

  Future<ApiResponse<T>> patch<T>(
    String path, {
    required T Function(Map<String, dynamic>) fromJson,
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      path,
      data: data,
      queryParameters: queryParameters,
    );
    return ApiResponse.fromJson(response.data!, fromJson);
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    required T Function(Map<String, dynamic>) fromJson,
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      path,
      data: data,
      queryParameters: queryParameters,
    );
    return ApiResponse.fromJson(response.data!, fromJson);
  }

  Future<PaginatedResponse<T>> getPaginated<T>(
    String path, {
    required T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      path,
      queryParameters: queryParameters,
    );
    return PaginatedResponse.fromJson(response.data!, fromJson);
  }
}

// -----------------------------------------------------------------------------
// Interceptors
// -----------------------------------------------------------------------------

class _AuthInterceptor extends Interceptor {
  final AuthTokenProvider _tokenProvider;

  _AuthInterceptor(this._tokenProvider);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenProvider();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final apiException = _mapDioException(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: apiException,
        message: apiException.message,
      ),
    );
  }

  ApiException _mapDioException(DioException err) {
    // Network-level failures (no response received).
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return NetworkException(message: err.message ?? 'Network error');
    }

    final response = err.response;
    if (response == null) {
      return NetworkException(message: err.message ?? 'No response');
    }

    final statusCode = response.statusCode ?? 0;
    final body = response.data;

    // Try to parse the structured error from the body.
    String code = 'unknown';
    String message = 'Something went wrong';
    Map<String, dynamic> details = const {};

    if (body is Map<String, dynamic>) {
      final errorMap = body['error'] as Map<String, dynamic>?;
      if (errorMap != null) {
        code = errorMap['code'] as String? ?? code;
        message = errorMap['message'] as String? ?? message;
        details = errorMap['details'] as Map<String, dynamic>? ?? details;
      }
    }

    return switch (statusCode) {
      401 => UnauthorizedException(
          code: code,
          message: message,
          details: details,
        ),
      404 => NotFoundException(
          code: code,
          message: message,
          details: details,
        ),
      409 => ConflictException(
          code: code,
          message: message,
          details: details,
        ),
      422 || 400 => ValidationException(
          statusCode: statusCode,
          code: code,
          message: message,
          details: details,
        ),
      429 => RateLimitException(
          code: code,
          message: message,
          details: details,
          retryAfter: Duration(
            seconds: int.tryParse(
                  response.headers.value('retry-after') ?? '',
                ) ??
                60,
          ),
        ),
      >= 500 => ServerException(
          statusCode: statusCode,
          code: code,
          message: message,
          details: details,
        ),
      _ => ApiException(
          statusCode: statusCode,
          code: code,
          message: message,
          details: details,
        ),
    };
  }
}
