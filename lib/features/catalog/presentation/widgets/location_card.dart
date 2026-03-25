import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:berezhok/core/theme/app_colors.dart';
import 'package:berezhok/core/theme/app_spacing.dart';
import 'package:berezhok/core/theme/app_typography.dart';
import 'package:berezhok/core/utils/formatters.dart';
import 'package:berezhok/core/widgets/widgets.dart';
import 'package:berezhok/features/catalog/domain/location.dart';

class LocationCard extends StatelessWidget {
  const LocationCard({required this.location, super.key});

  final FoodLocation location;

  @override
  Widget build(BuildContext context) {
    final category = location.category;

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => context.go('/catalog/${location.id}'),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent border
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: category.color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppSpacing.radiusLg),
                  bottomLeft: Radius.circular(AppSpacing.radiusLg),
                ),
              ),
            ),

            // Category icon square
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  category.icon,
                  color: category.color,
                  size: 30,
                ),
              ),
            ),

            // Info section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.lg,
                  right: AppSpacing.lg,
                  bottom: AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Name
                    Text(
                      location.name,
                      style: AppTypography.subtitle1,
                      maxLines: 1,
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

                    // Rating
                    if (location.rating != null)
                      RatingStars(
                        rating: location.rating!.average,
                        size: 14,
                        showValue: true,
                        totalReviews: location.rating!.totalReviews,
                      ),
                    const SizedBox(height: AppSpacing.xs),

                    // Distance + active boxes
                    Row(
                      children: [
                        if (location.distance != null) ...[
                          Icon(
                            Icons.place_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            formatDistance(location.distance!),
                            style: AppTypography.caption,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text('·', style: AppTypography.caption),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: location.activeBoxesCount > 0
                                ? AppColors.success
                                : AppColors.textHint,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          _formatBoxesCount(location.activeBoxesCount),
                          style: AppTypography.caption.copyWith(
                            color: location.activeBoxesCount > 0
                                ? AppColors.success
                                : AppColors.textSecondary,
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
