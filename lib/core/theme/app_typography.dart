import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  static TextStyle get heading1 => const TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    height: 1.16,
  );

  static TextStyle get heading2 => const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    height: 1.18,
  );

  static TextStyle get heading3 => const TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    height: 1.24,
  );

  static TextStyle get subtitle1 => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    height: 1.28,
  );

  static TextStyle get subtitle2 => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    height: 1.28,
  );

  static TextStyle get body1 => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    height: 1.42,
  );

  static TextStyle get body2 => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static TextStyle get caption => const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static TextStyle get button => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.2,
  );

  static TextStyle get price => const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
    color: AppColors.primary,
    height: 1.2,
  );

  static TextStyle get priceOriginal => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.textSecondary,
    decoration: TextDecoration.lineThrough,
    decorationColor: AppColors.textSecondary,
    height: 1.2,
  );

  static TextStyle get label => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    color: AppColors.textSecondary,
    height: 1.3,
  );
}
