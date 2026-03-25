abstract final class AppConstants {
  // API
  static const String apiBaseUrl = 'https://api.berezhok.ru/v1';

  // Auth
  static const String tokenKey = 'auth_token';
  static const int smsCodeLength = 6;
  static const Duration smsCodeTtl = Duration(minutes: 5);

  // Orders
  static const Duration confirmationTimeout = Duration(minutes: 30);
  static const Duration autoCompleteDelay = Duration(minutes: 15);

  // Search & Map
  static const int defaultSearchRadius = 5000; // meters
  static const double defaultMapCenterLat = 55.7558;
  static const double defaultMapCenterLng = 37.6173;
  static const double defaultMapZoom = 13.0;

  // Business limits
  static const int maxActiveBoxes = 5;
}
