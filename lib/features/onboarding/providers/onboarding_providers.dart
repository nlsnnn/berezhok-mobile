import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final onboardingStateProvider =
    AsyncNotifierProvider<OnboardingNotifier, bool>(() => OnboardingNotifier());

class OnboardingNotifier extends AsyncNotifier<bool> {
  static const _onboardingCompletedKey = 'onboarding_completed';

  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, true);
    state = const AsyncData(true);
  }
}
