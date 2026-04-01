import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tuish_food/core/enums/user_role.dart';
import 'package:tuish_food/features/admin/user_management/data/datasources/user_management_datasource.dart';
import 'package:tuish_food/features/admin/user_management/data/repositories/user_management_repository_impl.dart';
import 'package:tuish_food/features/admin/user_management/domain/repositories/user_management_repository.dart';
import 'package:tuish_food/features/auth/domain/entities/app_user.dart';
import 'package:tuish_food/injection_container.dart';

// ---------------------------------------------------------------------------
// Datasource & Repository
// ---------------------------------------------------------------------------

final userManagementDatasourceProvider =
    Provider<UserManagementDatasource>((ref) {
  return UserManagementDatasourceImpl(ref.watch(firestoreProvider));
});

final userManagementRepositoryProvider =
    Provider<UserManagementRepository>((ref) {
  return UserManagementRepositoryImpl(
    ref.watch(userManagementDatasourceProvider),
  );
});

// ---------------------------------------------------------------------------
// Filter state
// ---------------------------------------------------------------------------

/// Current role filter: null = all, otherwise UserRole.claimValue string.
class UserRoleFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void update(String? value) {
    state = value;
  }
}

final userRoleFilterProvider =
    NotifierProvider<UserRoleFilterNotifier, String?>(
        UserRoleFilterNotifier.new);

/// Current search query.
class UserSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) {
    state = value;
  }
}

final userSearchQueryProvider =
    NotifierProvider<UserSearchQueryNotifier, String>(
        UserSearchQueryNotifier.new);

// ---------------------------------------------------------------------------
// All users (with role filter)
// ---------------------------------------------------------------------------

final allUsersProvider =
    FutureProvider.autoDispose<List<AppUser>>((ref) async {
  final repo = ref.watch(userManagementRepositoryProvider);
  final roleFilter = ref.watch(userRoleFilterProvider);
  final searchQuery = ref.watch(userSearchQueryProvider);

  final result = await repo.getAllUsers(
    roleFilter: roleFilter,
    searchQuery: searchQuery.isNotEmpty ? searchQuery : null,
  );
  return result.fold(
    (failure) => throw Exception(failure.message),
    (users) => users,
  );
});

/// Users filtered by a specific role (family provider).
final usersByRoleProvider =
    FutureProvider.autoDispose.family<List<AppUser>, String>(
  (ref, role) async {
    final repo = ref.watch(userManagementRepositoryProvider);
    final result = await repo.getAllUsers(roleFilter: role);
    return result.fold(
      (failure) => throw Exception(failure.message),
      (users) => users,
    );
  },
);

// ---------------------------------------------------------------------------
// Single user detail
// ---------------------------------------------------------------------------

final userDetailProvider =
    FutureProvider.autoDispose.family<AppUser, String>((ref, userId) async {
  final repo = ref.watch(userManagementRepositoryProvider);
  final result = await repo.getUserById(userId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (user) => user,
  );
});

// ---------------------------------------------------------------------------
// Ban / Unban
// ---------------------------------------------------------------------------

class BanUserNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  UserManagementRepository get _repository =>
      ref.watch(userManagementRepositoryProvider);

  Future<bool> banUser(String userId) async {
    state = const AsyncValue.loading();
    final result = await _repository.banUser(userId);
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncValue.data(null);
        ref.invalidate(allUsersProvider);
        ref.invalidate(userDetailProvider(userId));
        return true;
      },
    );
  }

  Future<bool> unbanUser(String userId) async {
    state = const AsyncValue.loading();
    final result = await _repository.unbanUser(userId);
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncValue.data(null);
        ref.invalidate(allUsersProvider);
        ref.invalidate(userDetailProvider(userId));
        return true;
      },
    );
  }
}

final banUserProvider =
    NotifierProvider<BanUserNotifier, AsyncValue<void>>(
        BanUserNotifier.new);

// ---------------------------------------------------------------------------
// Verify delivery partner
// ---------------------------------------------------------------------------

class VerifyPartnerNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  UserManagementRepository get _repository =>
      ref.watch(userManagementRepositoryProvider);

  Future<bool> verify(String userId) async {
    state = const AsyncValue.loading();
    final result = await _repository.verifyDeliveryPartner(userId);
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncValue.data(null);
        ref.invalidate(allUsersProvider);
        ref.invalidate(userDetailProvider(userId));
        return true;
      },
    );
  }
}

final verifyPartnerProvider =
    NotifierProvider<VerifyPartnerNotifier, AsyncValue<void>>(
        VerifyPartnerNotifier.new);

// ---------------------------------------------------------------------------
// Update role
// ---------------------------------------------------------------------------

class UpdateRoleNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  UserManagementRepository get _repository =>
      ref.watch(userManagementRepositoryProvider);

  Future<bool> updateRole(String userId, UserRole role) async {
    state = const AsyncValue.loading();
    final result = await _repository.updateUserRole(userId, role);
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncValue.data(null);
        ref.invalidate(allUsersProvider);
        ref.invalidate(userDetailProvider(userId));
        return true;
      },
    );
  }
}

final updateRoleProvider =
    NotifierProvider<UpdateRoleNotifier, AsyncValue<void>>(
        UpdateRoleNotifier.new);
