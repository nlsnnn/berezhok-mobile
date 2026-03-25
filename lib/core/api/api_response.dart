/// Generic API response models matching the backend contract.
///
/// Success: {"success": true, "data": {...}}
/// Error:   {"success": false, "error": {"code": "...", "message": "...", "details": {...}}}
library;

class ApiError {
  final String code;
  final String message;
  final Map<String, dynamic> details;

  const ApiError({
    required this.code,
    required this.message,
    this.details = const {},
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      code: json['code'] as String? ?? 'unknown',
      message: json['message'] as String? ?? 'Unknown error',
      details: json['details'] as Map<String, dynamic>? ?? const {},
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'message': message,
        'details': details,
      };

  @override
  String toString() => 'ApiError(code: $code, message: $message)';
}

class ApiResponse<T> {
  final bool success;
  final T? data;
  final ApiError? error;

  const ApiResponse({
    required this.success,
    this.data,
    this.error,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final success = json['success'] as bool? ?? false;
    return ApiResponse(
      success: success,
      data: success && json['data'] != null
          ? fromJsonT(json['data'] as Map<String, dynamic>)
          : null,
      error: !success && json['error'] != null
          ? ApiError.fromJson(json['error'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convenience factory for responses where data is a primitive or
  /// already-parsed value (e.g. a plain string or bool).
  factory ApiResponse.fromJsonRaw(Map<String, dynamic> json) {
    final success = json['success'] as bool? ?? false;
    return ApiResponse(
      success: success,
      data: success ? json['data'] as T? : null,
      error: !success && json['error'] != null
          ? ApiError.fromJson(json['error'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  String toString() =>
      'ApiResponse(success: $success, data: $data, error: $error)';
}

class Pagination {
  final int total;
  final int limit;
  final int offset;
  final bool hasMore;

  const Pagination({
    required this.total,
    required this.limit,
    required this.offset,
    required this.hasMore,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'] as int? ?? 0,
      limit: json['limit'] as int? ?? 20,
      offset: json['offset'] as int? ?? 0,
      hasMore: json['has_more'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'total': total,
        'limit': limit,
        'offset': offset,
        'has_more': hasMore,
      };

  @override
  String toString() =>
      'Pagination(total: $total, limit: $limit, offset: $offset, hasMore: $hasMore)';
}

class PaginatedResponse<T> {
  final bool success;
  final List<T> items;
  final Pagination pagination;
  final ApiError? error;

  const PaginatedResponse({
    required this.success,
    required this.items,
    required this.pagination,
    this.error,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final success = json['success'] as bool? ?? false;
    final data = json['data'] as Map<String, dynamic>? ?? {};

    final rawItems = data['items'] as List<dynamic>? ?? [];
    final items = rawItems
        .cast<Map<String, dynamic>>()
        .map(fromJsonT)
        .toList(growable: false);

    final paginationJson =
        data['pagination'] as Map<String, dynamic>? ?? const {};

    return PaginatedResponse(
      success: success,
      items: items,
      pagination: Pagination.fromJson(paginationJson),
      error: !success && json['error'] != null
          ? ApiError.fromJson(json['error'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  String toString() =>
      'PaginatedResponse(success: $success, items: ${items.length}, pagination: $pagination)';
}
