abstract final class RoutePaths {
  // Root
  static const String splash = '/';

  // Auth
  static const String auth = '/auth';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String phoneVerify = '/auth/phone-verify';
  static const String forgotPassword = '/auth/forgot-password';
  static const String roleSelection = '/auth/role-selection';

  // Customer
  static const String customerHome = '/customer/home';
  static const String restaurantDetail = '/customer/home/restaurant/:id';
  static const String restaurantMenuItem =
      '/customer/home/restaurant/:id/item/:itemId';
  static const String searchScreen = '/customer/home/search';

  static const String customerOrders = '/customer/orders';
  static const String orderDetail = '/customer/orders/:orderId';
  static const String orderTracking = '/customer/orders/:orderId/tracking';
  static const String orderReview = '/customer/orders/:orderId/review';
  static const String orderChat = '/customer/orders/:orderId/chat';
  static const String customerCart = '/customer/cart';
  static const String customerProfile = '/customer/profile';
  static const String editProfile = '/customer/profile/edit';
  static const String addresses = '/customer/profile/addresses';
  static const String addAddress = '/customer/profile/addresses/add';
  static const String customerSettings = '/customer/profile/settings';
  static const String customerNotifications = '/customer/profile/notifications';

  // Checkout (full screen, no shell)
  static const String checkout = '/checkout';
  static const String checkoutAddress = '/checkout/address';
  static const String checkoutPayment = '/checkout/payment';
  static const String orderConfirmation = '/checkout/confirmation/:orderId';

  // Delivery Partner
  static const String deliveryHome = '/delivery/home';
  static const String deliveryOrders = '/delivery/orders';
  static const String deliveryOrderDetail = '/delivery/orders/:orderId';
  static const String deliveryNavigation = '/delivery/orders/:orderId/navigate';
  static const String deliveryChat = '/delivery/orders/:orderId/chat';
  static const String deliveryEarnings = '/delivery/earnings';
  static const String deliveryProfile = '/delivery/profile';

  // Restaurant Owner
  static const String restaurantDashboard = '/restaurant/dashboard';
  static const String restaurantSetup = '/restaurant/setup';
  static const String restaurantOwnerMenu = '/restaurant/menu';
  static const String restaurantAddMenuItem = '/restaurant/menu/add';
  static const String restaurantEditMenuItem = '/restaurant/menu/:itemId/edit';
  static const String restaurantOrders = '/restaurant/orders';
  static const String restaurantOrderDetail = '/restaurant/orders/:orderId';
  static const String restaurantProfile = '/restaurant/profile';

  // Admin
  static const String adminDashboard = '/admin/dashboard';
  static const String adminRestaurants = '/admin/restaurants';
  static const String addRestaurant = '/admin/restaurants/add';
  static const String editRestaurant = '/admin/restaurants/:id/edit';
  static const String restaurantMenu = '/admin/restaurants/:id/menu';
  static const String adminUsers = '/admin/users';
  static const String adminUserDetail = '/admin/users/:id';
  static const String adminDeliveryPartners = '/admin/delivery-partners';
  static const String adminOrders = '/admin/orders';
  static const String adminOrderDetail = '/admin/orders/:orderId';
  static const String adminPromotions = '/admin/promotions';
  static const String createPromotion = '/admin/promotions/create';
  static const String adminSettings = '/admin/settings';
}
