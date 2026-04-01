enum PaymentStatus {
  pending,
  completed,
  failed,
  refunded;

  String get displayName {
    return switch (this) {
      PaymentStatus.pending => 'Pending',
      PaymentStatus.completed => 'Completed',
      PaymentStatus.failed => 'Failed',
      PaymentStatus.refunded => 'Refunded',
    };
  }

  String get firestoreValue => name;

  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => PaymentStatus.pending,
    );
  }
}
