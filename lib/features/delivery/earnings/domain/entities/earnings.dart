import 'package:equatable/equatable.dart';

class Earnings extends Equatable {
  final String id;
  final String deliveryPartnerId;
  final String orderId;
  final String orderNumber;
  final double deliveryFee;
  final double tip;
  final double bonus;
  final double totalEarned;
  final DateTime date;
  final String week;
  final String month;
  final bool isPaidOut;

  const Earnings({
    required this.id,
    required this.deliveryPartnerId,
    required this.orderId,
    required this.orderNumber,
    required this.deliveryFee,
    required this.tip,
    required this.bonus,
    required this.totalEarned,
    required this.date,
    required this.week,
    required this.month,
    required this.isPaidOut,
  });

  @override
  List<Object?> get props => [
        id,
        deliveryPartnerId,
        orderId,
        orderNumber,
        deliveryFee,
        tip,
        bonus,
        totalEarned,
        date,
        week,
        month,
        isPaidOut,
      ];
}
