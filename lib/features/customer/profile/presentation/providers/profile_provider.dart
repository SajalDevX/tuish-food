import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tuish_food/features/auth/domain/entities/app_user.dart';
import 'package:tuish_food/features/auth/presentation/providers/auth_provider.dart';
import 'package:tuish_food/features/auth/presentation/providers/auth_state.dart';
import 'package:tuish_food/features/customer/profile/data/datasources/profile_remote_datasource.dart';
import 'package:tuish_food/features/customer/profile/data/repositories/profile_repository_impl.dart';
import 'package:tuish_food/features/customer/profile/domain/entities/address.dart';
import 'package:tuish_food/features/customer/profile/domain/repositories/profile_repository.dart';
import 'package:tuish_food/injection_container.dart';

// Data source
final profileRemoteDataSourceProvider =
    Provider<ProfileRemoteDataSource>((ref) {
  return ProfileRemoteDataSourceImpl(
    firestore: ref.watch(firestoreProvider),
  );
});

// Repository
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(
    remoteDataSource: ref.watch(profileRemoteDataSourceProvider),
  );
});

// Current user profile (from auth)
final userProfileProvider = Provider<AppUser?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return switch (authState) {
    Authenticated(:final user) => user,
    _ => null,
  };
});

// Addresses
final addressesProvider =
    FutureProvider.family<List<Address>, String>((ref, userId) async {
  final repository = ref.watch(profileRepositoryProvider);
  final result = await repository.getAddresses(userId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (addresses) => addresses,
  );
});

// Update profile notifier
final updateProfileProvider =
    NotifierProvider<UpdateProfileNotifier, AsyncValue<void>>(
        UpdateProfileNotifier.new);

class UpdateProfileNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  ProfileRepository get _repository => ref.watch(profileRepositoryProvider);

  Future<bool> updateProfile({
    required String userId,
    String? displayName,
    String? email,
    String? phone,
    String? photoUrl,
  }) async {
    state = const AsyncLoading();
    final result = await _repository.updateProfile(
      userId: userId,
      displayName: displayName,
      email: email,
      phone: phone,
      photoUrl: photoUrl,
    );
    return result.fold(
      (failure) {
        state = AsyncError(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData(null);
        return true;
      },
    );
  }
}

// Address management notifier
final addressManagementProvider =
    NotifierProvider<AddressManagementNotifier, AsyncValue<void>>(
        AddressManagementNotifier.new);

class AddressManagementNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  ProfileRepository get _repository => ref.watch(profileRepositoryProvider);

  Future<bool> addAddress(String userId, Address address) async {
    state = const AsyncLoading();
    final result = await _repository.addAddress(userId, address);
    return result.fold(
      (failure) {
        state = AsyncError(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData(null);
        return true;
      },
    );
  }

  Future<bool> deleteAddress(String userId, String addressId) async {
    state = const AsyncLoading();
    final result = await _repository.deleteAddress(userId, addressId);
    return result.fold(
      (failure) {
        state = AsyncError(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData(null);
        return true;
      },
    );
  }

  Future<bool> setDefaultAddress(
      String userId, String addressId) async {
    state = const AsyncLoading();
    final result =
        await _repository.setDefaultAddress(userId, addressId);
    return result.fold(
      (failure) {
        state = AsyncError(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData(null);
        return true;
      },
    );
  }
}
