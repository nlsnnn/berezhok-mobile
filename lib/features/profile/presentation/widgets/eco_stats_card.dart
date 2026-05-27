import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:berezhok/core/theme/app_colors.dart';
import 'package:berezhok/core/theme/app_spacing.dart';
import 'package:berezhok/core/theme/app_typography.dart';
import 'package:berezhok/features/profile/domain/eco_stats.dart';

/// Eco-account gamification card shown on the profile screen.
///
/// Shows the user's current tier badge with chevrons, a hero number (total kg
/// saved), descriptive copy, and three bottom stats.
class EcoStatsCard extends StatelessWidget {
  const EcoStatsCard({
    required this.stats,
    required this.displayName,
    super.key,
  });

  final EcoStats stats;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4EC),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ---- Header row ----
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: label + greeting
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ВАШ ЭКО-СЧЁТ',
                        style: AppTypography.label.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '$displayName, привет 👋',
                        style: AppTypography.subtitle1.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Right: tier badge
                _TierBadge(tier: stats.tier),
              ],
            ),
          ),

          // ---- Hero number ----
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  stats.totalKg.round().toString(),
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDark,
                    height: 0.95,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'КГ СПАСЕНО',
                    style: AppTypography.subtitle2.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ---- Description text ----
          if (stats.mealsEquivalent > 0) ...[
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text(
                'Это примерно как ${_pluralMeals(stats.mealsEquivalent)}, '
                'которые могли бы поехать в мусор. '
                'Вы экономите ${_formatRub(stats.savingsRub ~/ 12)} в месяц.',
                style: AppTypography.body2.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text(
                'Сделайте первый заказ — и начните спасать еду от утилизации.',
                style: AppTypography.body2.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],

          // ---- Divider ----
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            child: Divider(
              color: AppColors.primaryDark.withValues(alpha: 0.12),
              height: 1,
            ),
          ),

          // ---- Bottom stats ----
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: Row(
              children: [
                _BottomStat(
                  value: stats.boxesPickedUp.toString(),
                  label: _pluralBoxesLabel(stats.boxesPickedUp),
                ),
                _VerticalDivider(),
                _BottomStat(
                  value: '${stats.co2SavedKg.round()} кг',
                  label: 'CO₂ НЕ ВЫПУЩЕНО',
                ),
                _VerticalDivider(),
                _BottomStat(
                  value: _formatRub(stats.savingsRub),
                  label: 'ЭКОНОМИЯ ЗА ГОД',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Tier badge (top-right corner)
// =============================================================================

class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.tier});

  final EcoTier tier;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          tier.displayName,
          style: AppTypography.label.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 5),
        _TierChevrons(filled: tier.chevronsFilled),
      ],
    );
  }
}

/// Five short diagonal-stroke chevrons; [filled] of them are opaque.
class _TierChevrons extends StatelessWidget {
  const _TierChevrons({required this.filled});

  final int filled;

  static const int _total = 5;
  static const double _barW = 8;
  static const double _barH = 14;
  static const double _gap = 3;
  static const double _skew = -0.25; // radians for slight italic lean

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_total, (i) {
        final active = i < filled;
        return Padding(
          padding: EdgeInsets.only(left: i == 0 ? 0 : _gap),
          child: Transform(
            transform: Matrix4.skewX(_skew),
            child: Container(
              width: _barW,
              height: _barH,
              decoration: BoxDecoration(
                color: active
                    ? AppColors.primaryDark
                    : AppColors.primaryDark.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// =============================================================================
// Bottom stats
// =============================================================================

class _BottomStat extends StatelessWidget {
  const _BottomStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTypography.subtitle1.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.label.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
              letterSpacing: 0.3,
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      color: AppColors.primaryDark.withValues(alpha: 0.12),
    );
  }
}

// =============================================================================
// Shimmer placeholder
// =============================================================================

/// Skeleton placeholder while eco stats are loading.
class EcoStatsCardShimmer extends StatelessWidget {
  const EcoStatsCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4EC),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppSpacing.cardShadow,
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Helpers
// =============================================================================

/// Russian plural: «1 обед / 2 обеда / 5 обедов»
String _pluralMeals(int n) {
  final mod10 = n % 10;
  final mod100 = n % 100;
  String word;
  if (mod10 == 1 && mod100 != 11) {
    word = 'обед';
  } else if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) {
    word = 'обеда';
  } else {
    word = 'обедов';
  }
  return '≈ $n $word';
}

/// Label for boxes stat (only the noun, uppercased).
String _pluralBoxesLabel(int n) {
  final mod10 = n % 10;
  final mod100 = n % 100;
  if (mod10 == 1 && mod100 != 11) return 'БОКС ЗАБРАН';
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) {
    return 'БОКСА ЗАБРАНО';
  }
  return 'БОКСОВ ЗАБРАНО';
}

/// Format integer rubles with space thousands separator: «12 420 ₽»
String _formatRub(int rub) {
  final fmt = NumberFormat('#,##0', 'ru_RU');
  // NumberFormat in ru_RU uses non-breaking thin space — replace with normal space
  return '${fmt.format(rub).replaceAll(' ', ' ')} ₽';
}
