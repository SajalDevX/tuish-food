import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:tuish_food/core/constants/firebase_constants.dart';
import 'package:tuish_food/core/errors/exceptions.dart';
import 'package:tuish_food/features/customer/profile/data/models/address_model.dart';
import 'package:tuish_food/features/customer/profile/domain/entities/address.dart';

abstract class ProfileRemoteDataSource {
  Future<void> updateProfile({
    required String userId,
    String? displayName,
    String? email,
    String? phone,
    String? photoUrl,
  });

  Future<List<AddressModel>> getAddresses(String userId);
  Future<void> addAddress(String userId, Address address);
  Future<void> deleteAddress(String userId, String addressId);
  Future<void> setDefaultAddress(String userId, String addressId);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final FirebaseFirestore _firestore;

  const ProfileRemoteDataSourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  DocumentReference _userDoc(String userId) =>
      _firestore.collection(FirebaseConstants.usersCollection).doc(userId);

  CollectionReference _addressesRef(String userId) =>
      _userDoc(userId)
          .collection(FirebaseConstants.addressesSubcollection);

  @override
  Future<void> updateProfile({
    required String userId,
    String? displayName,
    String? email,
    String? phone,
    String? photoUrl,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (displayName != null) updates['displayName'] = displayName;
      if (email != null) updates['email'] = email;
      if (phone != null) updates['phone'] = phone;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      await _userDoc(userId).update(updates);
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to update profile');
    }
  }

  @override
  Future<List<AddressModel>> getAddresses(String userId) async {
    try {
      final snapshot = await _addressesRef(userId).get();
      return snapshot.docs
          .map((doc) => AddressModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to fetch addresses');
    }
  }

  @override
  Future<void> addAddress(String userId, Address address) async {
    try {
      final model = AddressModel.fromEntity(address);

      // If this is the first address or marked as default, set as default
      if (address.isDefault) {
        await _clearDefaultAddresses(userId);
      }

      if (address.id.isNotEmpty) {
        await _addressesRef(userId)
            .doc(address.id)
            .set(model.toFirestore());
      } else {
        await _addressesRef(userId).add(model.toFirestore());
      }
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to add address');
    }
  }

  @override
  Future<void> deleteAddress(String userId, String addressId) async {
    try {
      await _addressesRef(userId).doc(addressId).delete();
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to delete address');
    }
  }

  @override
  Future<void> setDefaultAddress(
      String userId, String addressId) async {
    try {
      // Clear all defaults first
      await _clearDefaultAddresses(userId);

      // Set the new default
      await _addressesRef(userId)
          .doc(addressId)
          .update({'isDefault': true});
    } on FirebaseException catch (e) {
      throw ServerException(
          e.message ?? 'Failed to set default address');
    }
  }

  Future<void> _clearDefaultAddresses(String userId) async {
    final snapshot = await _addressesRef(userId)
        .where('isDefault', isEqualTo: true)
        .get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isDefault': false});
    }
    await batch.commit();
  }
}
