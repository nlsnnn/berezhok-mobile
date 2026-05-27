/// All API endpoint paths used by the mobile app.
///
/// Constant paths are static const fields.
/// Paths containing dynamic IDs are static methods.
library;

abstract final class ApiEndpoints {
  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------
  static const String sendCode = '/auth/customer/send-code';
  static const String login = '/auth/customer/login';

  // ---------------------------------------------------------------------------
  // Customer profile
  // ---------------------------------------------------------------------------
  static const String profile = '/customer/profile';
  static const String updateProfile = '/customer/profile';

  // ---------------------------------------------------------------------------
  // Locations
  // ---------------------------------------------------------------------------
  static const String locations = '/customer/locations';

  static String locationDetail(String id) => '/customer/locations/$id';
  static String locationReviews(String locationId) =>
      '/customer/locations/$locationId/reviews';

  // ---------------------------------------------------------------------------
  // Orders
  // ---------------------------------------------------------------------------
  static const String createOrder = '/customer/orders';
  static const String orders = '/customer/orders';

  static String orderDetail(String id) => '/customer/orders/$id';
  static String confirmPickup(String id) => '/customer/orders/$id/confirm-pickup';
  static String dispute(String id) => '/customer/orders/$id/dispute';

  // ---------------------------------------------------------------------------
  // Reviews
  // ---------------------------------------------------------------------------
  static const String createReview = '/customer/reviews';

  // ---------------------------------------------------------------------------
  // Push tokens
  // ---------------------------------------------------------------------------
  static const String registerPushToken = '/customer/push-tokens';

  // ---------------------------------------------------------------------------
  // Eco-account
  // ---------------------------------------------------------------------------
  static const String ecoStats = '/customer/eco-stats';
}
