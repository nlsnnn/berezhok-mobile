import 'package:berezhok/features/profile/domain/user_profile.dart';
import 'profile_repository.dart';

class MockProfileRepository implements ProfileRepository {
  UserProfile _profile = const UserProfile(
    id: 'c1a2b3c4-d5e6-4f78-a9b0-c1d2e3f4g5h6',
    phone: '+7 (999) 123-45-67',
    name: 'Алексей Иванов',
    createdAt: null,
  );

  @override
  Future<UserProfile> getProfile() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _profile;
  }

  @override
  Future<UserProfile> updateProfile({
    String? name,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _profile = _profile.copyWith(
      name: name,
    );
    return _profile;
  }
}
