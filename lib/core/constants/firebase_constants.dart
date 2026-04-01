abstract final class FirebaseConstants {
  // Firestore Collections
  static const String usersCollection = 'users';
  static const String restaurantsCollection = 'restaurants';
  static const String ordersCollection = 'orders';
  static const String reviewsCollection = 'reviews';
  static const String deliveryLocationsCollection = 'delivery_locations';
  static const String chatsCollection = 'chats';
  static const String earningsCollection = 'earnings';
  static const String promotionsCollection = 'promotions';
  static const String notificationsCollection = 'notifications';
  static const String appConfigCollection = 'app_config';

  // Subcollections
  static const String addressesSubcollection = 'addresses';
  static const String menuCategoriesSubcollection = 'menuCategories';
  static const String menuItemsSubcollection = 'menuItems';
  static const String messagesSubcollection = 'messages';

  // App Config Document
  static const String settingsDoc = 'settings';

  // Storage Paths
  static const String usersStoragePath = 'users';
  static const String restaurantsStoragePath = 'restaurants';
  static const String reviewsStoragePath = 'reviews';
  static const String chatStoragePath = 'chat';
  static const String promotionsStoragePath = 'promotions';

  // Custom Claims
  static const String roleClaimKey = 'role';
}
