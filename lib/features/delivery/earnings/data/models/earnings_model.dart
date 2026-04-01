import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tuish_food/features/delivery/earnings/domain/entities/earnings.dart';

class EarningsModel extends Earnings {
  const EarningsModel({
    required super.id,
    required super.deliveryPartnerId,
    required super.orderId,
    required super.orderNumber,
    required super.deliveryFee,
    required super.tip,
    required super.bonus,
    required super.totalEarned,
    required super.date,
    required super.week,
    required super.month,
    required super.isPaidOut,
  });

  factory EarningsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;

    return EarningsModel(
      id: doc.id,
      deliveryPartnerId: data['deliveryPartnerId'] as String? ?? '',
      orderId: data['orderId'] as String? ?? '',
      orderNumber: data['orderNumber'] as String? ?? '',
      deliveryFee: (data['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      tip: (data['tip'] as num?)?.toDouble() ?? 0.0,
      bonus: (data['bonus'] as num?)?.toDouble() ?? 0.0,
      totalEarned: (data['totalEarned'] as num?)?.toDouble() ?? 0.0,
      date: data['date'] != null
          ? (data['date'] as Timestamp).toDate()
          : DateTime.now(),
      week: data['week'] as String? ?? '',
      month: data['month'] as String? ?? '',
      isPaidOut: data['isPaidOut'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deliveryPartnerId': deliveryPartnerId,
      'orderId': orderId,
      'orderNumber': orderNumber,
      'deliveryFee': deliveryFee,
      'tip': tip,
      'bonus': bonus,
      'totalEarned': totalEarned,
      'date': Timestamp.fromDate(date),
      'week': week,
      'month': month,
      'isPaidOut': isPaidOut,
    };
  }
}
