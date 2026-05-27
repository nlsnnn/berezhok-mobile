import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:berezhok/features/auth/domain/user.dart';
import 'auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  final FlutterSecureStorage _secureStorage;

  MockAuthRepository({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  @override
  Future<void> sendCode(String phone) async {
    // Simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 500));
    // Always succeeds in mock
  }

  @override
  Future<User> verifyCode(String phone, String code) async {
    // Simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 800));

    if (code.length != 6) {
      throw Exception('Неверный код. Введите 6-значный код.');
    }

    // Generate a fake JWT token
    final token = _generateFakeToken();
    await saveToken(token);

    // Create and persist user
    final user = User(
      id: 'user_${Random().nextInt(99999)}',
      phone: phone,
      name: '',
      createdAt: DateTime.now(),
    );

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

  String _generateFakeToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return 'mock_jwt_${base64Url.encode(bytes)}';
  }

  /// Update user name in local storage.
  @override
  Future<User?> updateUserName(String name) async {
    final currentUser = await getCurrentUser();
    if (currentUser == null) return null;

    final updated = currentUser.copyWith(name: name);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(updated.toJson()));

    return updated;
  }
}
