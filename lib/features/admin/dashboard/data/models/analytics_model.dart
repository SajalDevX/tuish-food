import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:tuish_food/features/admin/dashboard/domain/entities/analytics_data.dart';

class RevenueDataPointModel extends RevenueDataPoint {
  const RevenueDataPointModel({
    required super.date,
    required super.revenue,
  });

  factory RevenueDataPointModel.fromMap(Map<String, dynamic> map) {
    return RevenueDataPointModel(
      date: (map['date'] as Timestamp).toDate(),
      revenue: (map['revenue'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'revenue': revenue,
    };
  }
}

class TopRestaurantModel extends TopRestaurant {
  const TopRestaurantModel({
    required super.id,
    required super.name,
    required super.totalOrders,
    required super.totalRevenue,
  });

  factory TopRestaurantModel.fromMap(Map<String, dynamic> map) {
    return TopRestaurantModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      totalOrders: (map['totalOrders'] as num?)?.toInt() ?? 0,
      totalRevenue: (map['totalRevenue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'totalOrders': totalOrders,
      'totalRevenue': totalRevenue,
    };
  }
}

class AnalyticsModel extends AnalyticsData {
  const AnalyticsModel({
    required super.totalOrders,
    required super.totalRevenue,
    required super.activeUsers,
    required super.activeDeliveryPartners,
    required super.avgDeliveryTimeMinutes,
    required super.ordersByStatus,
    required super.revenueByDay,
    required super.topRestaurants,
    required super.period,
  });

  factory AnalyticsModel.fromMap(Map<String, dynamic> map) {
    return AnalyticsModel(
      totalOrders: (map['totalOrders'] as num?)?.toInt() ?? 0,
      totalRevenue: (map['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      activeUsers: (map['activeUsers'] as num?)?.toInt() ?? 0,
      activeDeliveryPartners:
          (map['activeDeliveryPartners'] as num?)?.toInt() ?? 0,
      avgDeliveryTimeMinutes:
          (map['avgDeliveryTimeMinutes'] as num?)?.toDouble() ?? 0.0,
      ordersByStatus: Map<String, int>.from(
        (map['ordersByStatus'] as Map<String, dynamic>?)?.map(
              (key, value) => MapEntry(key, (value as num).toInt()),
            ) ??
            {},
      ),
      revenueByDay: (map['revenueByDay'] as List<dynamic>?)
              ?.map((e) =>
                  RevenueDataPointModel.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      topRestaurants: (map['topRestaurants'] as List<dynamic>?)
              ?.map((e) =>
                  TopRestaurantModel.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      period: map['period'] as String? ?? 'today',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalOrders': totalOrders,
      'totalRevenue': totalRevenue,
      'activeUsers': activeUsers,
      'activeDeliveryPartners': activeDeliveryPartners,
      'avgDeliveryTimeMinutes': avgDeliveryTimeMinutes,
      'ordersByStatus': ordersByStatus,
      'revenueByDay': revenueByDay
          .map((e) => {
                'date': Timestamp.fromDate(e.date),
                'revenue': e.revenue,
              })
          .toList(),
      'topRestaurants': topRestaurants
          .map((e) => {
                'id': e.id,
                'name': e.name,
                'totalOrders': e.totalOrders,
                'totalRevenue': e.totalRevenue,
              })
          .toList(),
      'period': period,
    };
  }
}
