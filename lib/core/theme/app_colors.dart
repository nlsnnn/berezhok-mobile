import 'package:flutter/material.dart';

abstract final class AppColors {
  // Primary palette — urban fresh green
  static const Color primary = Color(0xFF1F6F4A);
  static const Color primaryLight = Color(0xFF3F9B6B);
  static const Color primaryDark = Color(0xFF12432E);
  static const Color primarySoft = Color(0xFFE8F5EE);

  // Accent/Secondary — fresh lime and food coral
  static const Color accent = Color(0xFFFF6F45);
  static const Color accentLight = Color(0xFFFFA37F);
  static const Color lime = Color(0xFFC7F36A);
  static const Color limeSoft = Color(0xFFF1F9D7);

  // Background
  static const Color background = Color(0xFFFBFAF6);
  static const Color cardWhite = Color(0xFFFFFFFF);

  // Surface
  static const Color surface = Color(0xFFF3F1EA);
  static const Color surfaceElevated = Color(0xFFFFFEFA);
  static const Color surfacePressed = Color(0xFFEAE7DF);

  // Text
  static const Color textPrimary = Color(0xFF16201A);
  static const Color textSecondary = Color(0xFF657068);
  static const Color textHint = Color(0xFF9AA29B);

  // Semantic
  static const Color success = Color(0xFF2DA44E);
  static const Color warning = Color(0xFFE59722);
  static const Color error = Color(0xFFD92D20);
  static const Color info = Color(0xFF247BA0);

  // Rating
  static const Color ratingStar = Color(0xFFFFB020);

  // Category colors (matching DB schema)
  static const Color categoryBakery = Color(0xFFFF6F45);
  static const Color categoryCafe = Color(0xFF159A9C);
  static const Color categoryRestaurant = Color(0xFF247BA0);
  static const Color categoryGrocery = Color(0xFFEF8A34);
  static const Color categoryHotel = Color(0xFF7A6FF0);

  // Divider
  static const Color divider = Color(0xFFE2DED3);
  static const Color border = Color(0xFFDAD6CC);

  // Shadow
  static final Color shadow = Colors.black.withValues(alpha: 0.055);
  static final Color strongShadow = Colors.black.withValues(alpha: 0.12);

  // Shimmer
  static const Color shimmerBase = Color(0xFFEDE9DF);
  static const Color shimmerHighlight = Color(0xFFF8F6F0);
}
