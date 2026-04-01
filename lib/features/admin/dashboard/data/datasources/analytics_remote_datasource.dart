import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:tuish_food/core/constants/firebase_constants.dart';
import 'package:tuish_food/core/errors/exceptions.dart';
import 'package:tuish_food/features/admin/dashboard/data/models/analytics_model.dart';

abstract class AnalyticsRemoteDatasource {
  Future<AnalyticsModel> getDashboardStats(String period);
  Future<List<RevenueDataPointModel>> getRevenueReport(
    DateTime startDate,
    DateTime endDate,
  );
  Future<Map<String, int>> getOrderAnalytics();
}

class AnalyticsRemoteDatasourceImpl implements AnalyticsRemoteDatasource {
  final FirebaseFirestore _firestore;

  const AnalyticsRemoteDatasourceImpl(this._firestore);

  DateTime _periodStartDate(String period) {
    final now = DateTime.now();
    return switch (period) {
      'today' => DateTime(now.year, now.month, now.day),
      'week' => now.subtract(const Duration(days: 7)),
      'month' => DateTime(now.year, now.month - 1, now.day),
      'year' => DateTime(now.year - 1, now.month, now.day),
      _ => DateTime(now.year, now.month, now.day),
    };
  }

  @override
  Future<AnalyticsModel> getDashboardStats(String period) async {
    try {
      final startDate = _periodStartDate(period);
      final startTimestamp = Timestamp.fromDate(startDate);

      // Fetch orders within period
      final ordersSnapshot = await _firestore
          .collection(FirebaseConstants.ordersCollection)
          .where('createdAt', isGreaterThanOrEqualTo: startTimestamp)
          .get();

      final orders = ordersSnapshot.docs;

      int totalOrders = orders.length;
      double totalRevenue = 0;
      final Map<String, int> ordersByStatus = {};
      double totalDeliveryTime = 0;
      int deliveredCount = 0;

      for (final doc in orders) {
        final data = doc.data();
        totalRevenue += (data['totalAmount'] as num?)?.toDouble() ?? 0;

        final status = data['status'] as String? ?? 'placed';
        ordersByStatus[status] = (ordersByStatus[status] ?? 0) + 1;

        if (status == 'delivered' &&
            data['createdAt'] != null &&
            data['actualDeliveryTime'] != null) {
          final created = (data['createdAt'] as Timestamp).toDate();
          final delivered = (data['actualDeliveryTime'] as Timestamp).toDate();
          totalDeliveryTime +=
              delivered.difference(created).inMinutes.toDouble();
          deliveredCount++;
        }
      }

      final avgDeliveryTime =
          deliveredCount > 0 ? totalDeliveryTime / deliveredCount : 0.0;

      // Active users count
      final usersSnapshot = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .where('isActive', isEqualTo: true)
          .get();
      final activeUsers = usersSnapshot.docs.length;

      // Active delivery partners count
      final deliveryPartnersSnapshot = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .where('role', isEqualTo: 'deliveryPartner')
          .where('isActive', isEqualTo: true)
          .get();
      final activeDeliveryPartners = deliveryPartnersSnapshot.docs.length;

      // Revenue by day - aggregate orders by date
      final Map<String, double> revenueMap = {};
      for (final doc in orders) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp).toDate();
        final dateKey =
            '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
        final amount = (data['totalAmount'] as num?)?.toDouble() ?? 0;
        revenueMap[dateKey] = (revenueMap[dateKey] ?? 0) + amount;
      }

      final revenueByDay = revenueMap.entries.map((e) {
        final parts = e.key.split('-');
        return RevenueDataPointModel(
          date: DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          ),
          revenue: e.value,
        );
      }).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      // Top restaurants by order count
      final Map<String, Map<String, dynamic>> restaurantStats = {};
      for (final doc in orders) {
        final data = doc.data();
        final restaurantId = data['restaurantId'] as String? ?? '';
        final restaurantName = data['restaurantName'] as String? ?? 'Unknown';
        final amount = (data['totalAmount'] as num?)?.toDouble() ?? 0;

        if (restaurantId.isNotEmpty) {
          if (!restaurantStats.containsKey(restaurantId)) {
            restaurantStats[restaurantId] = {
              'name': restaurantName,
              'totalOrders': 0,
              'totalRevenue': 0.0,
            };
          }
          restaurantStats[restaurantId]!['totalOrders'] =
              (restaurantStats[restaurantId]!['totalOrders'] as int) + 1;
          restaurantStats[restaurantId]!['totalRevenue'] =
              (restaurantStats[restaurantId]!['totalRevenue'] as double) +
                  amount;
        }
      }

      final topRestaurants = restaurantStats.entries
          .map((e) => TopRestaurantModel(
                id: e.key,
                name: e.value['name'] as String,
                totalOrders: e.value['totalOrders'] as int,
                totalRevenue: e.value['totalRevenue'] as double,
              ))
          .toList()
        ..sort((a, b) => b.totalOrders.compareTo(a.totalOrders));

      return AnalyticsModel(
        totalOrders: totalOrders,
        totalRevenue: totalRevenue,
        activeUsers: activeUsers,
        activeDeliveryPartners: activeDeliveryPartners,
        avgDeliveryTimeMinutes: avgDeliveryTime,
        ordersByStatus: ordersByStatus,
        revenueByDay: revenueByDay,
        topRestaurants:
            topRestaurants.take(5).toList(),
        period: period,
      );
    } catch (e) {
      throw ServerException('Failed to fetch dashboard stats: $e');
    }
  }

  @override
  Future<List<RevenueDataPointModel>> getRevenueReport(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final ordersSnapshot = await _firestore
          .collection(FirebaseConstants.ordersCollection)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .where('status', isEqualTo: 'delivered')
          .get();

      final Map<String, double> revenueMap = {};
      for (final doc in ordersSnapshot.docs) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp).toDate();
        final dateKey =
            '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
        final amount = (data['totalAmount'] as num?)?.toDouble() ?? 0;
        revenueMap[dateKey] = (revenueMap[dateKey] ?? 0) + amount;
      }

      return revenueMap.entries.map((e) {
        final parts = e.key.split('-');
        return RevenueDataPointModel(
          date: DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          ),
          revenue: e.value,
        );
      }).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
    } catch (e) {
      throw ServerException('Failed to fetch revenue report: $e');
    }
  }

  @override
  Future<Map<String, int>> getOrderAnalytics() async {
    try {
      final ordersSnapshot = await _firestore
          .collection(FirebaseConstants.ordersCollection)
          .get();

      final Map<String, int> analytics = {};
      for (final doc in ordersSnapshot.docs) {
        final status = doc.data()['status'] as String? ?? 'placed';
        analytics[status] = (analytics[status] ?? 0) + 1;
      }
      return analytics;
    } catch (e) {
      throw ServerException('Failed to fetch order analytics: $e');
    }
  }
}
