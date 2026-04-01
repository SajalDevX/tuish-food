import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tuish_food/core/constants/firebase_constants.dart';
import 'package:tuish_food/injection_container.dart';

/// A lightweight map representation for notifications, avoiding the need
/// for a full domain layer since notifications are presentation-only.
typedef AppNotification = Map<String, dynamic>;

// Stream of notifications for the current user, ordered by newest first
final userNotificationsProvider =
    StreamProvider<List<AppNotification>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  final firestore = ref.watch(firestoreProvider);

  if (currentUser == null) {
    return Stream.value([]);
  }

  return firestore
      .collection(FirebaseConstants.notificationsCollection)
      .where('userId', isEqualTo: currentUser.uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return <String, dynamic>{
              'id': doc.id,
              'userId': data['userId'] as String? ?? '',
              'type': data['type'] as String? ?? 'system',
              'title': data['title'] as String? ?? '',
              'body': data['body'] as String? ?? '',
              'isRead': data['isRead'] as bool? ?? false,
              'data': data['data'] as Map<String, dynamic>? ?? {},
              'createdAt':
                  (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            };
          }).toList());
});

// Count of unread notifications
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(userNotificationsProvider);
  return notificationsAsync.when(
    data: (notifications) =>
        notifications.where((n) => n['isRead'] == false).length,
    loading: () => 0,
    error: (_, _) => 0,
  );
});

// Mark a single notification as read
final markNotificationReadProvider =
    Provider<MarkNotificationReadAction>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return MarkNotificationReadAction(firestore);
});

class MarkNotificationReadAction {
  final FirebaseFirestore _firestore;

  const MarkNotificationReadAction(this._firestore);

  Future<void> call(String notificationId) async {
    await _firestore
        .collection(FirebaseConstants.notificationsCollection)
        .doc(notificationId)
        .update({'isRead': true});
  }
}

// Mark all notifications as read
final markAllNotificationsReadProvider =
    Provider<MarkAllNotificationsReadAction>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final currentUser = ref.watch(currentUserProvider);
  return MarkAllNotificationsReadAction(firestore, currentUser?.uid);
});

class MarkAllNotificationsReadAction {
  final FirebaseFirestore _firestore;
  final String? _userId;

  const MarkAllNotificationsReadAction(this._firestore, this._userId);

  Future<void> call() async {
    if (_userId == null) return;

    final snapshot = await _firestore
        .collection(FirebaseConstants.notificationsCollection)
        .where('userId', isEqualTo: _userId)
        .where('isRead', isEqualTo: false)
        .get();

    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
