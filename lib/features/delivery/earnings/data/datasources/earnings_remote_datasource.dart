import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tuish_food/core/constants/firebase_constants.dart';
import 'package:tuish_food/core/errors/exceptions.dart';
import 'package:tuish_food/features/delivery/earnings/data/models/earnings_model.dart';

abstract class EarningsRemoteDatasource {
  Future<List<EarningsModel>> getDailyEarnings(DateTime date);
  Future<List<EarningsModel>> getWeeklyEarnings(String week);
  Future<List<EarningsModel>> getEarningsHistory(int limit);
}

class EarningsRemoteDatasourceImpl implements EarningsRemoteDatasource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  const EarningsRemoteDatasourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  String get _currentUserId {
    final user = _auth.currentUser;
    if (user == null) throw const AuthException('User not authenticated');
    return user.uid;
  }

  CollectionReference get _earningsCollection =>
      _firestore.collection(FirebaseConstants.earningsCollection);

  @override
  Future<List<EarningsModel>> getDailyEarnings(DateTime date) async {
    try {
      final userId = _currentUserId;
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _earningsCollection
          .where('deliveryPartnerId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => EarningsModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get daily earnings: $e');
    }
  }

  @override
  Future<List<EarningsModel>> getWeeklyEarnings(String week) async {
    try {
      final userId = _currentUserId;

      final snapshot = await _earningsCollection
          .where('deliveryPartnerId', isEqualTo: userId)
          .where('week', isEqualTo: week)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => EarningsModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get weekly earnings: $e');
    }
  }

  @override
  Future<List<EarningsModel>> getEarningsHistory(int limit) async {
    try {
      final userId = _currentUserId;

      final snapshot = await _earningsCollection
          .where('deliveryPartnerId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => EarningsModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get earnings history: $e');
    }
  }
}
