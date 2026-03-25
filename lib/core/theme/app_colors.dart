import 'package:flutter/material.dart';

abstract final class AppColors {
  // Primary palette — muted forest green
  static const Color primary = Color(0xFF3B7A57);
  static const Color primaryLight = Color(0xFF5BA67C);
  static const Color primaryDark = Color(0xFF2D5E43);

  // Accent/Secondary — warm coral
  static const Color accent = Color(0xFFE8734A);
  static const Color accentLight = Color(0xFFF09E7A);

  // Background
  static const Color background = Color(0xFFFAFAF7);
  static const Color cardWhite = Color(0xFFFFFFFF);

  // Surface
  static const Color surface = Color(0xFFF5F3EF);

  // Text
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textHint = Color(0xFFA0A0A0);

  // Semantic
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);

  // Rating
  static const Color ratingStar = Color(0xFFFFB800);

  // Category colors (matching DB schema)
  static const Color categoryBakery = Color(0xFFFF6B6B);
  static const Color categoryCafe = Color(0xFF4ECDC4);
  static const Color categoryRestaurant = Color(0xFF45B7D1);
  static const Color categoryGrocery = Color(0xFFFFA07A);
  static const Color categoryHotel = Color(0xFF98D8C8);

  // Divider
  static const Color divider = Color(0xFFE8E5DF);

  // Shadow
  static final Color shadow = Colors.black.withValues(alpha: 0.06);

  // Shimmer
  static const Color shimmerBase = Color(0xFFEDEAE4);
  static const Color shimmerHighlight = Color(0xFFF5F3EF);
}
