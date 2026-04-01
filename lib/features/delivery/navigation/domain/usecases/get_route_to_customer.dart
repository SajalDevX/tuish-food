import 'package:dartz/dartz.dart';
import 'package:tuish_food/core/errors/failures.dart';
import 'package:tuish_food/features/delivery/navigation/domain/repositories/navigation_repository.dart';

class GetRouteToCustomer {
  final NavigationRepository repository;

  const GetRouteToCustomer(this.repository);

  Future<Either<Failure, RouteInfo>> call(
    double customerLat,
    double customerLng,
  ) {
    return repository.getRouteToCustomer(customerLat, customerLng);
  }
}
