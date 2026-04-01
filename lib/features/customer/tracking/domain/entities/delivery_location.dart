import 'package:equatable/equatable.dart';

class DeliveryLocation extends Equatable {
  final String partnerId;
  final double latitude;
  final double longitude;
  final double heading;
  final double speed;
  final DateTime updatedAt;

  const DeliveryLocation({
    required this.partnerId,
    required this.latitude,
    required this.longitude,
    this.heading = 0,
    this.speed = 0,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        partnerId,
        latitude,
        longitude,
        heading,
        speed,
        updatedAt,
      ];
}
