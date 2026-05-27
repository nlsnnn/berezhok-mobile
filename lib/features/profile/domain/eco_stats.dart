/// Eco-account stats model — matches GET /api/v1/customer/eco-stats response.
library;

/// Gamification tier ladder (ordered by threshold).
enum EcoTier {
  newcomer,
  helper,
  guardian,
  keeper,
  hero;

  /// Human-readable Russian label shown in the badge.
  String get displayName {
    switch (this) {
      case EcoTier.newcomer:
        return 'НОВИЧОК';
      case EcoTier.helper:
        return 'ПОМОЩНИК';
      case EcoTier.guardian:
        return 'ЗАЩИТНИК';
      case EcoTier.keeper:
        return 'ХРАНИТЕЛЬ';
      case EcoTier.hero:
        return 'ЭКО-ГЕРОЙ';
    }
  }

  /// How many chevrons to fill (1-based, max 5).
  int get chevronsFilled => index + 1;

  static EcoTier fromString(String value) {
    return EcoTier.values.firstWhere(
      (t) => t.name == value,
      orElse: () => EcoTier.newcomer,
    );
  }
}

class EcoStats {
  const EcoStats({
    required this.boxesPickedUp,
    required this.totalKg,
    required this.co2SavedKg,
    required this.savingsRub,
    required this.mealsEquivalent,
    required this.tier,
    required this.tierProgress,
    required this.nextTier,
    required this.kgToNextTier,
  });

  final int boxesPickedUp;

  /// Total kg of food saved (rounded to 2 dp on backend).
  final double totalKg;

  /// CO₂ prevented = totalKg × 2.5.
  final double co2SavedKg;

  /// Sum of (original_price − discount_price) across all picked-up orders.
  final int savingsRub;

  /// "≈ N обедов" copytext helper.
  final int mealsEquivalent;

  final EcoTier tier;

  /// 0..1 progress within current tier towards the next.
  final double tierProgress;

  /// null when the user is already on the top tier (hero).
  final EcoTier? nextTier;

  /// Kg remaining until the next tier; 0 at top tier.
  final double kgToNextTier;

  factory EcoStats.fromJson(Map<String, dynamic> json) => EcoStats(
        boxesPickedUp: (json['boxes_picked_up'] as num).toInt(),
        totalKg: (json['total_kg'] as num).toDouble(),
        co2SavedKg: (json['co2_saved_kg'] as num).toDouble(),
        savingsRub: (json['savings_rub'] as num).toInt(),
        mealsEquivalent: (json['meals_equivalent'] as num).toInt(),
        tier: EcoTier.fromString(json['tier'] as String),
        tierProgress: (json['tier_progress'] as num).toDouble(),
        nextTier: json['next_tier'] != null
            ? EcoTier.fromString(json['next_tier'] as String)
            : null,
        kgToNextTier: (json['kg_to_next_tier'] as num).toDouble(),
      );

  @override
  String toString() =>
      'EcoStats(tier: ${tier.name}, totalKg: $totalKg, boxes: $boxesPickedUp)';
}
