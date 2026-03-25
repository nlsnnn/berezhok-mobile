import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class LocationCategory {
  final String code;
  final String name;
  final String? iconUrl;

  const LocationCategory({
    required this.code,
    required this.name,
    this.iconUrl,
  });

  IconData get icon => switch (code) {
        'bakery' => Icons.bakery_dining,
        'cafe' => Icons.coffee,
        'restaurant' => Icons.restaurant,
        'grocery' => Icons.shopping_basket,
        'hotel' => Icons.hotel,
        _ => Icons.store,
      };

  Color get color => switch (code) {
        'bakery' => AppColors.categoryBakery,
        'cafe' => AppColors.categoryCafe,
        'restaurant' => AppColors.categoryRestaurant,
        'grocery' => AppColors.categoryGrocery,
        'hotel' => AppColors.categoryHotel,
        _ => AppColors.primary,
      };

  factory LocationCategory.fromJson(Map<String, dynamic> json) =>
      LocationCategory(
        code: json['code'] as String,
        name: json['name'] as String,
        iconUrl: json['icon_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        if (iconUrl != null) 'icon_url': iconUrl,
      };

  @override
  String toString() => 'LocationCategory(code: $code, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationCategory &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}
