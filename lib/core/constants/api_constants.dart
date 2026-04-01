abstract final class ApiConstants {
  // Cloud Functions callable endpoints
  static const String setUserRole = 'setUserRole';
  static const String calculateFees = 'calculateFees';
  static const String validateCoupon = 'validateCoupon';
  static const String getDashboardStats = 'getDashboardStats';
  static const String getRevenueReport = 'getRevenueReport';
  static const String getEarningsSummary = 'getEarningsSummary';
  static const String assignDeliveryPartner = 'assignDeliveryPartner';
  static const String processPayment = 'processPayment';
  static const String sendPromoNotification = 'sendPromoNotification';

  // Timeouts
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration longTimeout = Duration(seconds: 60);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;
}
