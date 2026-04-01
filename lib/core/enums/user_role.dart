enum UserRole {
  customer,
  deliveryPartner,
  admin;

  String get displayName {
    return switch (this) {
      UserRole.customer => 'Customer',
      UserRole.deliveryPartner => 'Delivery Partner',
      UserRole.admin => 'Admin',
    };
  }

  String get claimValue {
    return switch (this) {
      UserRole.customer => 'customer',
      UserRole.deliveryPartner => 'deliveryPartner',
      UserRole.admin => 'admin',
    };
  }

  static UserRole? fromString(String? value) {
    if (value == null) return null;
    return switch (value) {
      'customer' => UserRole.customer,
      'deliveryPartner' => UserRole.deliveryPartner,
      'admin' => UserRole.admin,
      _ => null,
    };
  }
}
