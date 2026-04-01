import 'package:equatable/equatable.dart';

import 'package:tuish_food/core/enums/user_role.dart';

class AppUser extends Equatable {
  final String uid;
  final String? email;
  final String? phone;
  final String? displayName;
  final String? photoUrl;
  final UserRole role;
  final bool isActive;
  final bool isBanned;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AppUser({
    required this.uid,
    this.email,
    this.phone,
    this.displayName,
    this.photoUrl,
    this.role = UserRole.customer,
    this.isActive = true,
    this.isBanned = false,
    this.createdAt,
    this.updatedAt,
  });

  AppUser copyWith({
    String? uid,
    String? email,
    String? phone,
    String? displayName,
    String? photoUrl,
    UserRole? role,
    bool? isActive,
    bool? isBanned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      isBanned: isBanned ?? this.isBanned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        email,
        phone,
        displayName,
        photoUrl,
        role,
        isActive,
        isBanned,
        createdAt,
        updatedAt,
      ];
}
