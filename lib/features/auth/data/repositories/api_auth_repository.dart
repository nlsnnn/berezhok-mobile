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
    final user = response.data!.user.copyWith(phone: phone);

    // Save token and user data locally
    await saveToken(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));

    return user;
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
