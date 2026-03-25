import 'package:flutter/material.dart';

import 'package:berezhok/core/theme/app_colors.dart';
import 'package:berezhok/core/theme/app_spacing.dart';
import 'package:berezhok/core/theme/app_typography.dart';
import 'package:berezhok/core/utils/formatters.dart';
import 'package:berezhok/core/widgets/widgets.dart';
import 'package:berezhok/features/catalog/domain/review.dart';

class ReviewCard extends StatelessWidget {
  const ReviewCard({required this.review, super.key});

  final Review review;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + stars
          Row(
            children: [
              Expanded(
                child: Text(
                  review.userName,
                  style: AppTypography.subtitle2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              RatingStars(
                rating: review.rating.toDouble(),
                size: 14,
              ),
            ],
          ),

          // Comment
          if (review.comment != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              review.comment!,
              style: AppTypography.body2,
            ),
          ],

          // Relative time
          const SizedBox(height: AppSpacing.xs),
          Text(
            formatRelativeTime(review.createdAt),
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
