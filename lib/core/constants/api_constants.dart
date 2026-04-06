abstract final class ApiConstants {
  // Razorpay — key_id is public (safe to be in source).
  // Override at build time via --dart-define=RAZORPAY_KEY_ID=<prod_key>.
  static const String razorpayKeyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: 'rzp_test_Sa4o1NtNOTCVfD',
  );

  // Cloud Functions callable endpoints
  static const String setUserRole = 'setUserRole';
  static const String calculateFees = 'calculateFees';
  static const String validateCoupon = 'validateCoupon';
  static const String getDashboardStats = 'getDashboardStats';
  static const String getRevenueReport = 'getRevenueReport';
  static const String getEarningsSummary = 'getEarningsSummary';
  static const String assignDeliveryPartner = 'assignDeliveryPartner';
  static const String createRazorpayOrder = 'createRazorpayOrder';
  static const String verifyRazorpayPayment = 'verifyRazorpayPayment';
  static const String processRazorpayRefund = 'processRazorpayRefund';
  static const String sendPromoNotification = 'sendPromoNotification';
  static const String createSubscription = 'createSubscription';
  static const String cancelSubscription = 'cancelSubscription';

  // Timeouts
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration longTimeout = Duration(seconds: 60);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;
}
