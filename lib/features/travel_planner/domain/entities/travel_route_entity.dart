import 'package:atlas/features/travel_planner/domain/entities/travel_location_entity.dart';

enum TravelTransportType { best, car, bus, train, flight }

enum TravelLegType {
  car,
  bus,
  train,
  subway,
  tram,
  walking,
  bicycle,
  flight,
  transfer,
}

class TravelRouteEntity {
  final String id;
  final TravelTransportType transportType;
  final String title;
  final String summary;
  final Duration duration;
  final int distanceMeters;
  final String? priceLabel;
  final int transferCount;
  final bool isMocked;
  final bool isEstimated;
  final String? bookingUrl;
  final List<TravelRouteLegEntity> legs;

  const TravelRouteEntity({
    required this.id,
    required this.transportType,
    required this.title,
    required this.summary,
    required this.duration,
    required this.distanceMeters,
    required this.transferCount,
    required this.legs,
    this.priceLabel,
    this.isMocked = false,
    this.isEstimated = false,
    this.bookingUrl,
  });

  String get durationLabel {
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);

    if (days > 0) {
      return hours > 0 ? '${days}d ${hours}h' : '${days}d';
    }
    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
    return '${minutes}m';
  }
}

class TravelRouteLegEntity {
  final TravelLegType type;
  final String title;
  final String fromName;
  final String toName;
  final String? operatorName;
  final String? lineName;
  final DateTime? departureTime;
  final DateTime? arrivalTime;
  final Duration duration;
  final int distanceMeters;
  final String instructions;

  const TravelRouteLegEntity({
    required this.type,
    required this.title,
    required this.fromName,
    required this.toName,
    required this.duration,
    required this.distanceMeters,
    this.operatorName,
    this.lineName,
    this.departureTime,
    this.arrivalTime,
    this.instructions = '',
  });
}

class TravelRoutePlanEntity {
  final TravelLocationEntity origin;
  final TravelLocationEntity destination;
  final List<TravelRouteEntity> routes;
  final List<TravelStopEntity> pointsOfInterest;
  final List<TravelStopEntity> hotels;

  const TravelRoutePlanEntity({
    required this.origin,
    required this.destination,
    required this.routes,
    required this.pointsOfInterest,
    required this.hotels,
  });
}

class TravelStopEntity {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double? rating;
  final int userRatingCount;
  final String? photoReference;
  final String category;

  const TravelStopEntity({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.userRatingCount,
    required this.category,
    this.rating,
    this.photoReference,
  });
}
