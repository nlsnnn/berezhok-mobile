import 'package:berezhok/features/profile/domain/eco_stats.dart';
import 'eco_stats_repository.dart';

class MockEcoStatsRepository implements EcoStatsRepository {
  @override
  Future<EcoStats> getEcoStats() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return const EcoStats(
      boxesPickedUp: 47,
      totalKg: 42.0,
      co2SavedKg: 105.0,
      savingsRub: 12420,
      mealsEquivalent: 28,
      tier: EcoTier.keeper,
      tierProgress: 0.5,
      nextTier: EcoTier.hero,
      kgToNextTier: 50.0,
    );
  }
}
