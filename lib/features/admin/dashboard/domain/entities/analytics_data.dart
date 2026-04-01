import 'package:equatable/equatable.dart';

class RevenueDataPoint extends Equatable {
  final DateTime date;
  final double revenue;

  const RevenueDataPoint({
    required this.date,
    required this.revenue,
  });

  @override
  List<Object?> get props => [date, revenue];
}

class TopRestaurant extends Equatable {
  final String id;
  final String name;
  final int totalOrders;
  final double totalRevenue;

  const TopRestaurant({
    required this.id,
    required this.name,
    required this.totalOrders,
    required this.totalRevenue,
  });

  @override
  List<Object?> get props => [id, name, totalOrders, totalRevenue];
}

class AnalyticsData extends Equatable {
  final int totalOrders;
  final double totalRevenue;
  final int activeUsers;
  final int activeDeliveryPartners;
  final double avgDeliveryTimeMinutes;
  final Map<String, int> ordersByStatus;
  final List<RevenueDataPoint> revenueByDay;
  final List<TopRestaurant> topRestaurants;
  final String period;

  const AnalyticsData({
    required this.totalOrders,
    required this.totalRevenue,
    required this.activeUsers,
    required this.activeDeliveryPartners,
    required this.avgDeliveryTimeMinutes,
    required this.ordersByStatus,
    required this.revenueByDay,
    required this.topRestaurants,
    required this.period,
  });

  @override
  List<Object?> get props => [
        totalOrders,
        totalRevenue,
        activeUsers,
        activeDeliveryPartners,
        avgDeliveryTimeMinutes,
        ordersByStatus,
        revenueByDay,
        topRestaurants,
        period,
      ];
}
