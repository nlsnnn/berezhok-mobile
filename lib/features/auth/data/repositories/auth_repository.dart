import 'package:berezhok/features/auth/domain/user.dart';

abstract class AuthRepository {
  Future<void> sendCode(String phone);
  Future<User> verifyCode(String phone, String code);
  Future<User?> getCurrentUser();
  Future<User?> updateUserName(String name);
  Future<void> logout();
  Future<String?> getToken();
  Future<void> saveToken(String token);
}
