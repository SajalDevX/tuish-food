import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tuish_food/features/delivery/earnings/data/datasources/earnings_remote_datasource.dart';
import 'package:tuish_food/features/delivery/earnings/data/repositories/earnings_repository_impl.dart';
import 'package:tuish_food/features/delivery/earnings/domain/entities/earnings.dart';
import 'package:tuish_food/features/delivery/earnings/domain/repositories/earnings_repository.dart';
import 'package:tuish_food/injection_container.dart';

// ---------------------------------------------------------------------------
// Datasource & Repository providers
// ---------------------------------------------------------------------------

final earningsRemoteDatasourceProvider =
    Provider<EarningsRemoteDatasource>((ref) {
  return EarningsRemoteDatasourceImpl(
    firestore: ref.watch(firestoreProvider),
    auth: ref.watch(firebaseAuthProvider),
  );
});

final earningsRepositoryProvider = Provider<EarningsRepository>((ref) {
  return EarningsRepositoryImpl(
    remoteDatasource: ref.watch(earningsRemoteDatasourceProvider),
  );
});

// ---------------------------------------------------------------------------
// Today's earnings
// ---------------------------------------------------------------------------

final todayEarningsProvider =
    FutureProvider<List<Earnings>>((ref) async {
  final repository = ref.watch(earningsRepositoryProvider);
  final result = await repository.getDailyEarnings(DateTime.now());
  return result.fold(
    (failure) => throw Exception(failure.message),
    (earnings) => earnings,
  );
});

// ---------------------------------------------------------------------------
// Weekly earnings
// ---------------------------------------------------------------------------

/// Returns the ISO week string for the current week (e.g. "2026-W13").
String _currentWeekString() {
  final now = DateTime.now();
  // ISO week number calculation.
  final dayOfYear = int.parse(DateFormat('D').format(now));
  final weekNumber = ((dayOfYear - now.weekday + 10) / 7).floor();
  return '${now.year}-W${weekNumber.toString().padLeft(2, '0')}';
}

final weeklyEarningsProvider =
    FutureProvider<List<Earnings>>((ref) async {
  final repository = ref.watch(earningsRepositoryProvider);
  final result = await repository.getWeeklyEarnings(_currentWeekString());
  return result.fold(
    (failure) => throw Exception(failure.message),
    (earnings) => earnings,
  );
});

// ---------------------------------------------------------------------------
// Earnings history
// ---------------------------------------------------------------------------

final earningsHistoryProvider =
    FutureProvider<List<Earnings>>((ref) async {
  final repository = ref.watch(earningsRepositoryProvider);
  final result = await repository.getEarningsHistory(100);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (earnings) => earnings,
  );
});
