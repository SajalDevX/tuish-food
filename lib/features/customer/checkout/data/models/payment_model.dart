import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tuish_food/core/enums/payment_status.dart';
import 'package:tuish_food/features/customer/checkout/domain/entities/payment.dart';

class PaymentModel extends Payment {
  const PaymentModel({
    required super.id,
    required super.method,
    required super.status,
    required super.amount,
    super.transactionId,
    super.razorpayOrderId,
    super.razorpayPaymentId,
    super.razorpaySignature,
  });

  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PaymentModel(
      id: doc.id,
      method: PaymentMethod.fromString(data['method'] as String? ?? ''),
      status: PaymentStatus.fromString(data['status'] as String? ?? 'pending'),
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      transactionId: data['transactionId'] as String?,
      razorpayOrderId: data['razorpayOrderId'] as String?,
      razorpayPaymentId: data['razorpayPaymentId'] as String?,
      razorpaySignature: data['razorpaySignature'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'method': method.firestoreValue,
      'status': status.firestoreValue,
      'amount': amount,
      if (transactionId != null) 'transactionId': transactionId,
      if (razorpayOrderId != null) 'razorpayOrderId': razorpayOrderId,
      if (razorpayPaymentId != null) 'razorpayPaymentId': razorpayPaymentId,
      if (razorpaySignature != null) 'razorpaySignature': razorpaySignature,
    };
  }

  factory PaymentModel.fromEntity(Payment payment) {
    return PaymentModel(
      id: payment.id,
      method: payment.method,
      status: payment.status,
      amount: payment.amount,
      transactionId: payment.transactionId,
      razorpayOrderId: payment.razorpayOrderId,
      razorpayPaymentId: payment.razorpayPaymentId,
      razorpaySignature: payment.razorpaySignature,
    );
  }
}
