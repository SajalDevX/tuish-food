import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:tuish_food/core/constants/firebase_constants.dart';
import 'package:tuish_food/core/enums/user_role.dart';
import 'package:tuish_food/core/errors/exceptions.dart';
import 'package:tuish_food/features/auth/data/models/user_model.dart';

abstract class UserManagementDatasource {
  Future<List<UserModel>> getAllUsers({
    String? roleFilter,
    String? searchQuery,
  });

  Future<UserModel> getUserById(String id);

  Future<void> banUser(String userId);

  Future<void> unbanUser(String userId);

  Future<void> verifyDeliveryPartner(String userId);

  Future<void> updateUserRole(String userId, UserRole role);
}

class UserManagementDatasourceImpl implements UserManagementDatasource {
  final FirebaseFirestore _firestore;

  const UserManagementDatasourceImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(FirebaseConstants.usersCollection);

  @override
  Future<List<UserModel>> getAllUsers({
    String? roleFilter,
    String? searchQuery,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _usersCollection;

      if (roleFilter != null && roleFilter.isNotEmpty) {
        query = query.where('role', isEqualTo: roleFilter);
      }

      query = query.orderBy('createdAt', descending: true);

      final snapshot = await query.get();
      var users = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();

      // Client-side search filter on displayName
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();
        users = users
            .where((user) =>
                (user.displayName?.toLowerCase().contains(lowerQuery) ??
                    false) ||
                (user.email?.toLowerCase().contains(lowerQuery) ?? false))
            .toList();
      }

      return users;
    } catch (e) {
      throw ServerException('Failed to fetch users: $e');
    }
  }

  @override
  Future<UserModel> getUserById(String id) async {
    try {
      final doc = await _usersCollection.doc(id).get();
      if (!doc.exists) {
        throw const ServerException('User not found');
      }
      return UserModel.fromFirestore(doc);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to fetch user: $e');
    }
  }

  @override
  Future<void> banUser(String userId) async {
    try {
      await _usersCollection.doc(userId).update({
        'isBanned': true,
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerException('Failed to ban user: $e');
    }
  }

  @override
  Future<void> unbanUser(String userId) async {
    try {
      await _usersCollection.doc(userId).update({
        'isBanned': false,
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerException('Failed to unban user: $e');
    }
  }

  @override
  Future<void> verifyDeliveryPartner(String userId) async {
    try {
      await _usersCollection.doc(userId).update({
        'isVerified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerException('Failed to verify delivery partner: $e');
    }
  }

  @override
  Future<void> updateUserRole(String userId, UserRole role) async {
    try {
      await _usersCollection.doc(userId).update({
        'role': role.claimValue,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerException('Failed to update user role: $e');
    }
  }
}
