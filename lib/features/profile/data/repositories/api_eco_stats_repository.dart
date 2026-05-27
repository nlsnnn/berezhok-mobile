import 'package:berezhok/core/api/api_client.dart';
import 'package:berezhok/core/api/api_endpoints.dart';
import 'package:berezhok/features/profile/domain/eco_stats.dart';
import 'eco_stats_repository.dart';

class ApiEcoStatsRepository implements EcoStatsRepository {
  ApiEcoStatsRepository(this._client);

  final ApiClient _client;

  @override
  Future<EcoStats> getEcoStats() async {
    final response = await _client.get<EcoStats>(
      ApiEndpoints.ecoStats,
      fromJson: EcoStats.fromJson,
    );

    if (!response.success || response.data == null) {
      throw Exception(response.error?.message ?? 'Failed to fetch eco stats');
    }

    return response.data!;
  }
}
