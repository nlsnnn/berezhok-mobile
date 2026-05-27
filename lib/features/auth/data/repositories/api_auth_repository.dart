import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:berezhok/core/api/api_client.dart';
import 'package:berezhok/core/api/api_endpoints.dart';
import 'package:berezhok/features/auth/domain/user.dart';
import 'auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  final ApiClient _apiClient;
  final FlutterSecureStorage _secureStorage;

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  ApiAuthRepository({
    required ApiClient apiClient,
    FlutterSecureStorage? secureStorage,
  })  : _apiClient = apiClient,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  @override
  Future<void> sendCode(String phone) async {
    await _apiClient.post(
      ApiEndpoints.sendCode,
      fromJson: (json) => json, // Simple response, no parsing needed
      data: {'phone': phone},
    );
  }

  @override
  Future<User> verifyCode(String phone, String code) async {
    final response = await _apiClient.post<_LoginResponse>(
      ApiEndpoints.login,
      fromJson: _LoginResponse.fromJson,
      data: {
        'phone': phone,
        'code': code,
      },
    );

    if (!response.success || response.data == null) {
      throw Exception(response.error?.message ?? 'Login failed');
    }

    final token = response.data!.token;
    var user = response.data!.user.copyWith(phone: phone);

    // Token must be saved before the profile call so the interceptor picks it up.
    await saveToken(token);

    // Best-effort: fetch profile to learn whether the user has already set their
    // name. Returning users skip the post-login setup screen this way.
    final fetchedName = await _tryFetchProfileName();
    if (fetchedName != null && fetchedName.isNotEmpty) {
      user = user.copyWith(name: fetchedName);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));

    return user;
  }

  Future<String?> _tryFetchProfileName() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.profile,
        fromJson: (json) => json,
      );
      if (!response.success || response.data == null) return null;
      return response.data!['name'] as String?;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    final token = await getToken();
    if (token == null) return null;

    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null) return null;

    try {
      final data = jsonDecode(userJson) as Map<String, dynamic>;
      return User.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<User?> updateUserName(String name) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      ApiEndpoints.updateProfile,
      fromJson: (json) => json,
      data: {'name': name},
    );

    if (!response.success) {
      throw Exception(response.error?.message ?? 'Failed to update name');
    }

    final current = await getCurrentUser();
    if (current == null) return null;

    final updated = current.copyWith(name: name);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(updated.toJson()));
    return updated;
  }

  @override
  Future<void> logout() async {
    await _secureStorage.delete(key: _tokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  @override
  Future<String?> getToken() async {
    return _secureStorage.read(key: _tokenKey);
  }

  @override
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }
}

/// Private response model for login endpoint
class _LoginResponse {
  final String token;
  final User user;

  _LoginResponse({
    required this.token,
    required this.user,
  });

  /// Server returns: {"user_id": "...", "token": "..."}
  /// We construct a minimal User from user_id and the phone we sent.
  factory _LoginResponse.fromJson(Map<String, dynamic> json) {
    final userId = json['user_id'] as String;
    return _LoginResponse(
      token: json['token'] as String,
      user: User(
        id: userId,
        phone: '', // phone comes from the request, not response
      ),
    );
  }
}
