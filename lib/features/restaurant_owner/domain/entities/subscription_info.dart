class SubscriptionInfo {
  final String status;
  final String? subscriptionId;
  final DateTime? currentEnd;
  final DateTime? graceDeadline;
  final bool isValid;

  const SubscriptionInfo({
    required this.status,
    this.subscriptionId,
    this.currentEnd,
    this.graceDeadline,
    required this.isValid,
  });

  bool get isActive => status == 'active';

  bool get isPending => status == 'pending';

  bool get isHalted => status == 'halted';

  bool get isCancelled => status == 'cancelled';

  bool get needsSubscription =>
      status == 'none' || status == 'halted' || status == 'cancelled';

  bool get isInGracePeriod => isPending && isValid && graceDeadline != null;

  factory SubscriptionInfo.none() => const SubscriptionInfo(
        status: 'none',
        isValid: false,
      );
}
