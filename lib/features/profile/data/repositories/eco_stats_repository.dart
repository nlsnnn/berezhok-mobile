import 'package:berezhok/features/profile/domain/eco_stats.dart';

abstract class EcoStatsRepository {
  Future<EcoStats> getEcoStats();
}
