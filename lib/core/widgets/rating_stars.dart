import 'package:flutter/material.dart';

import 'package:berezhok/core/theme/app_colors.dart';
import 'package:berezhok/core/theme/app_spacing.dart';
import 'package:berezhok/core/theme/app_typography.dart';

class RatingStars extends StatelessWidget {
  const RatingStars({
    required this.rating,
    this.maxStars = 5,
    this.size = 18,
    this.showValue = false,
    this.totalReviews,
    super.key,
  });

  final double rating;
  final int maxStars;
  final double size;
  final bool showValue;
  final int? totalReviews;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < maxStars; i++) ...[
          Icon(
            _iconForIndex(i),
            size: size,
            color: AppColors.ratingStar,
          ),
          if (i < maxStars - 1) const SizedBox(width: 1),
        ],
        if (showValue) ...[
          const SizedBox(width: AppSpacing.xs),
          Text(
            rating.toStringAsFixed(1),
            style: AppTypography.subtitle2.copyWith(fontSize: size * 0.78),
          ),
        ],
        if (totalReviews != null) ...[
          const SizedBox(width: AppSpacing.xs),
          Text(
            '($totalReviews)',
            style: AppTypography.caption.copyWith(fontSize: size * 0.67),
          ),
        ],
      ],
    );
  }

  IconData _iconForIndex(int index) {
    final starValue = index + 1;
    if (rating >= starValue) return Icons.star_rounded;
    if (rating >= starValue - 0.5) return Icons.star_half_rounded;
    return Icons.star_border_rounded;
  }
}
