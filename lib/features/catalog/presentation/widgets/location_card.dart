import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:berezhok/core/theme/app_colors.dart';
import 'package:berezhok/core/theme/app_spacing.dart';
import 'package:berezhok/core/theme/app_typography.dart';
import 'package:berezhok/core/utils/formatters.dart';
import 'package:berezhok/core/widgets/widgets.dart';
import 'package:berezhok/features/catalog/domain/location.dart';
import 'package:berezhok/features/catalog/domain/location_category.dart';

class LocationCard extends StatelessWidget {
  const LocationCard({required this.location, super.key});

  final FoodLocation location;

  @override
  Widget build(BuildContext context) {
    final category = location.category;

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push('/catalog/${location.id}'),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo or category icon square
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: SizedBox(
                  width: 78,
                  height: 88,
                  child: location.coverImageUrl != null
                      ? Image.network(
                          location.coverImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _CategoryIconFallback(category: category),
                        )
                      : location.logoUrl != null
                      ? Image.network(
                          location.logoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _CategoryIconFallback(category: category),
                        )
                      : _CategoryIconFallback(category: category),
                ),
              ),
            ),

            // Info section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.md,
                  right: AppSpacing.lg,
                  bottom: AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Name
                    Text(
                      location.name,
                      style: AppTypography.subtitle1,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    // Category + address
                    Text(
                      '${category.name} · ${location.address}',
                      style: AppTypography.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (location.rating != null)
                          RatingStars(
                            rating: location.rating!.average,
                            size: 14,
                            showValue: true,
                            totalReviews: location.rating!.totalReviews,
                          ),
                        if (location.distance != null)
                          _MetaPill(
                            icon: Icons.near_me_outlined,
                            label: formatDistance(location.distance!),
                          ),
                        _MetaPill(
                          icon: Icons.inventory_2_outlined,
                          label: _formatBoxesCount(location.activeBoxesCount),
                          color: location.activeBoxesCount > 0
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: category.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusFull,
                            ),
                          ),
                          child: Text(
                            'Смотреть боксы',
                            style: AppTypography.caption.copyWith(
                              color: category.color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBoxesCount(int count) {
    if (count == 0) return 'Нет боксов';
    final mod10 = count % 10;
    final mod100 = count % 100;
    final String word;
    if (mod100 >= 11 && mod100 <= 19) {
      word = 'боксов';
    } else if (mod10 == 1) {
      word = 'бокс';
    } else if (mod10 >= 2 && mod10 <= 4) {
      word = 'бокса';
    } else {
      word = 'боксов';
    }
    return '$count $word';
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    this.color = AppColors.textSecondary,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CategoryIconFallback extends StatelessWidget {
  const _CategoryIconFallback({required this.category});

  final LocationCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Icon(category.icon, color: category.color, size: 30),
    );
  }
}
