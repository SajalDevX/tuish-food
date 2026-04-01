import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tuish_food/core/constants/firebase_constants.dart';
import 'package:tuish_food/injection_container.dart';

// ---------------------------------------------------------------------------
// All promotions
// ---------------------------------------------------------------------------

final allPromotionsProvider = FutureProvider.autoDispose<
    List<QueryDocumentSnapshot<Map<String, dynamic>>>>((ref) async {
  final firestore = ref.watch(firestoreProvider);

  final snapshot = await firestore
      .collection(FirebaseConstants.promotionsCollection)
      .orderBy('createdAt', descending: true)
      .get();

  return snapshot.docs;
});

// ---------------------------------------------------------------------------
// Active promotions
// ---------------------------------------------------------------------------

final activePromotionsProvider = Provider.autoDispose<
    AsyncValue<List<QueryDocumentSnapshot<Map<String, dynamic>>>>>((ref) {
  final allAsync = ref.watch(allPromotionsProvider);
  final now = DateTime.now();

  return allAsync.whenData((promotions) {
    return promotions.where((doc) {
      final data = doc.data();
      final isActive = data['isActive'] as bool? ?? false;
      final validTo = (data['validTo'] as Timestamp?)?.toDate();
      return isActive && (validTo == null || validTo.isAfter(now));
    }).toList();
  });
});

// ---------------------------------------------------------------------------
// Expired promotions
// ---------------------------------------------------------------------------

final expiredPromotionsProvider = Provider.autoDispose<
    AsyncValue<List<QueryDocumentSnapshot<Map<String, dynamic>>>>>((ref) {
  final allAsync = ref.watch(allPromotionsProvider);
  final now = DateTime.now();

  return allAsync.whenData((promotions) {
    return promotions.where((doc) {
      final data = doc.data();
      final isActive = data['isActive'] as bool? ?? false;
      final validTo = (data['validTo'] as Timestamp?)?.toDate();
      return !isActive || (validTo != null && validTo.isBefore(now));
    }).toList();
  });
});

// ---------------------------------------------------------------------------
// Create promotion
// ---------------------------------------------------------------------------

class CreatePromotionNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  FirebaseFirestore get _firestore => ref.watch(firestoreProvider);

  Future<bool> createPromotion(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _firestore
          .collection(FirebaseConstants.promotionsCollection)
          .add({
        ...data,
        'usageCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      state = const AsyncValue.data(null);
      ref.invalidate(allPromotionsProvider);
      return true;
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
      return false;
    }
  }

  Future<bool> updatePromotion(
    String promotionId,
    Map<String, dynamic> data,
  ) async {
    state = const AsyncValue.loading();
    try {
      await _firestore
          .collection(FirebaseConstants.promotionsCollection)
          .doc(promotionId)
          .update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      state = const AsyncValue.data(null);
      ref.invalidate(allPromotionsProvider);
      return true;
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
      return false;
    }
  }
}

final createPromotionProvider =
    NotifierProvider<CreatePromotionNotifier, AsyncValue<void>>(
        CreatePromotionNotifier.new);
