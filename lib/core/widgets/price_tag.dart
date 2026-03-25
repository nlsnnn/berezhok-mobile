import 'package:flutter/material.dart';

import 'package:berezhok/core/theme/app_spacing.dart';
import 'package:berezhok/core/theme/app_typography.dart';

class PriceTag extends StatelessWidget {
  const PriceTag({
    required this.discountPrice,
    this.originalPrice,
    this.large = false,
    super.key,
  });

  final double discountPrice;
  final double? originalPrice;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final discountStyle = large
        ? AppTypography.price.copyWith(fontSize: 26)
        : AppTypography.price;
    final originalStyle = large
        ? AppTypography.priceOriginal.copyWith(fontSize: 16)
        : AppTypography.priceOriginal;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(_formatPrice(discountPrice), style: discountStyle),
        if (originalPrice != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Text(_formatPrice(originalPrice!), style: originalStyle),
        ],
      ],
    );
  }

  String _formatPrice(double value) {
    // Remove trailing zeros for clean look: 150.00 → "150", 99.50 → "99.50"
    final formatted = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
    return '$formatted ₽';
  }
}
