import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import 'package:tuish_food/core/enums/user_role.dart';
import 'package:tuish_food/features/auth/domain/entities/app_user.dart';

class UserModel extends AppUser {
  const UserModel({
    required super.uid,
    super.email,
    super.phone,
    super.displayName,
    super.photoUrl,
    super.role,
    super.isActive,
    super.isBanned,
    super.createdAt,
    super.updatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      email: data['email'] as String?,
      phone: data['phone'] as String?,
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      role: UserRole.fromString(data['role'] as String?),
      isActive: data['isActive'] as bool? ?? true,
      isBanned: data['isBanned'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory UserModel.fromFirebaseUser(
    firebase_auth.User user, {
    UserRole? role,
  }) {
    return UserModel(
      uid: user.uid,
      email: user.email,
      phone: user.phoneNumber,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      role: role,
      isActive: true,
      isBanned: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory UserModel.fromEntity(AppUser user) {
    return UserModel(
      uid: user.uid,
      email: user.email,
      phone: user.phone,
      displayName: user.displayName,
      photoUrl: user.photoUrl,
      role: user.role,
      isActive: user.isActive,
      isBanned: user.isBanned,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'phone': phone,
      'displayName': displayName,
      'photoUrl': photoUrl,
      if (role != null) 'role': role!.claimValue,
      'isActive': isActive,
      'isBanned': isBanned,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
