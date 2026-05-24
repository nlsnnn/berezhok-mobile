import 'package:flutter/material.dart';

import 'package:berezhok/core/theme/app_colors.dart';
import 'package:berezhok/core/theme/app_spacing.dart';
import 'package:berezhok/core/theme/app_typography.dart';
import 'package:berezhok/core/widgets/widgets.dart';
import 'package:berezhok/features/catalog/domain/surprise_box.dart';

class SurpriseBoxCard extends StatelessWidget {
  const SurpriseBoxCard({
    required this.box,
    this.onBook,
    this.isLoading = false,
    super.key,
  });

  final SurpriseBox box;
  final VoidCallback? onBook;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 260;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      box.name,
                      style: AppTypography.heading3,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.lime,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                    ),
                    child: Text(
                      '-${box.discountPercent}%',
                      style: AppTypography.subtitle2.copyWith(
                        color: AppColors.primaryDark,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),

              if (box.description != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  box.description!,
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              // Price row + pickup time
              if (isCompact)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PriceTag(
                      discountPrice: box.discountPrice,
                      originalPrice: box.originalPrice,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          box.pickupTimeFormatted,
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    PriceTag(
                      discountPrice: box.discountPrice,
                      originalPrice: box.originalPrice,
                    ),
                    const Spacer(),
                    Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        box.pickupTimeFormatted,
                        style: AppTypography.caption,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: AppSpacing.md),

              // Bottom row: remaining + book button
              if (isCompact)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _remainingText,
                      style: AppTypography.caption.copyWith(
                        color: box.quantityAvailable <= 2
                            ? AppColors.warning
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerRight,
                      child: AppButton(
                        label: 'Забронировать',
                        size: AppButtonSize.small,
                        isLoading: isLoading,
                        onPressed: box.quantityAvailable > 0 && !isLoading
                            ? onBook
                            : null,
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Text(
                      _remainingText,
                      style: AppTypography.caption.copyWith(
                        color: box.quantityAvailable <= 2
                            ? AppColors.warning
                            : AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    AppButton(
                      label: 'Забронировать',
                      size: AppButtonSize.small,
                      isLoading: isLoading,
                      onPressed: box.quantityAvailable > 0 && !isLoading
                          ? onBook
                          : null,
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  String get _remainingText {
    final word = switch (box.quantityAvailable) {
      1 => 'последний бокс',
      2 || 3 || 4 => 'осталось ${box.quantityAvailable} бокса',
      _ => 'осталось ${box.quantityAvailable} боксов',
    };
    return word;
  }
}
