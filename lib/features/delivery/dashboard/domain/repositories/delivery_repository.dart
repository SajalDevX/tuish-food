import 'package:dartz/dartz.dart';
import 'package:tuish_food/core/enums/order_status.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/delivery/dashboard/domain/entities/delivery_order.dart';

abstract class DeliveryRepository {
  /// Returns a stream of available orders (status == readyForPickup, unassigned).
  Stream<Either<Failure, List<DeliveryOrder>>> getAvailableOrders();

  /// Accepts an order, assigning it to the current delivery partner.
  Future<Either<Failure, DeliveryOrder>> acceptOrder(String orderId);

  /// Rejects an available order (marks it as skipped by the partner).
  Future<Either<Failure, void>> rejectOrder(String orderId);

  /// Updates the status of an order the partner is currently delivering.
  Future<Either<Failure, void>> updateOrderStatus(
    String orderId,
    OrderStatus status,
  );

  /// Returns the currently active delivery for this partner, if any.
  Future<Either<Failure, DeliveryOrder?>> getActiveDelivery();

  /// Returns the delivery history for this partner.
  Future<Either<Failure, List<DeliveryOrder>>> getDeliveryHistory();
}
