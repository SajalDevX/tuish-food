import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tuish_food/features/admin/dashboard/data/datasources/analytics_remote_datasource.dart';
import 'package:tuish_food/features/admin/dashboard/data/repositories/analytics_repository_impl.dart';
import 'package:tuish_food/features/admin/dashboard/domain/entities/analytics_data.dart';
import 'package:tuish_food/features/admin/dashboard/domain/repositories/analytics_repository.dart';
import 'package:tuish_food/features/admin/dashboard/domain/usecases/get_dashboard_stats.dart';
import 'package:tuish_food/features/admin/dashboard/domain/usecases/get_revenue_report.dart';
import 'package:tuish_food/injection_container.dart';

// Datasource
final analyticsRemoteDatasourceProvider =
    Provider<AnalyticsRemoteDatasource>((ref) {
  return AnalyticsRemoteDatasourceImpl(ref.watch(firestoreProvider));
});

// Repository
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepositoryImpl(ref.watch(analyticsRemoteDatasourceProvider));
});

// Use cases
final getDashboardStatsUseCaseProvider = Provider<GetDashboardStats>((ref) {
  return GetDashboardStats(ref.watch(analyticsRepositoryProvider));
});

final getRevenueReportUseCaseProvider = Provider<GetRevenueReport>((ref) {
  return GetRevenueReport(ref.watch(analyticsRepositoryProvider));
});

// Selected period state
class SelectedPeriodNotifier extends Notifier<String> {
  @override
  String build() => 'today';

  void update(String value) {
    state = value;
  }
}

final selectedPeriodProvider =
    NotifierProvider<SelectedPeriodNotifier, String>(
        SelectedPeriodNotifier.new);

// Dashboard stats
final dashboardStatsProvider =
    FutureProvider.autoDispose<AnalyticsData>((ref) async {
  final period = ref.watch(selectedPeriodProvider);
  final useCase = ref.watch(getDashboardStatsUseCaseProvider);
  final result = await useCase(period);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (data) => data,
  );
});

// Revenue report
final revenueReportProvider = FutureProvider.autoDispose
    .family<List<RevenueDataPoint>, ({DateTime start, DateTime end})>(
        (ref, params) async {
  final useCase = ref.watch(getRevenueReportUseCaseProvider);
  final result = await useCase(params.start, params.end);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (data) => data,
  );
});

// Recent orders stream for the dashboard
final recentOrdersProvider = StreamProvider.autoDispose<
    List<QueryDocumentSnapshot<Map<String, dynamic>>>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('orders')
      .orderBy('createdAt', descending: true)
      .limit(10)
      .snapshots()
      .map((snapshot) => snapshot.docs);
});
