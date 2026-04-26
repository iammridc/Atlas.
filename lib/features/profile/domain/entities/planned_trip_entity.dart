import 'package:atlas/features/travel_planner/domain/entities/travel_location_entity.dart';
import 'package:atlas/features/travel_planner/domain/entities/travel_route_entity.dart';

class PlannedTripEntity {
  final String id;
  final String title;
  final String routeSummary;
  final String note;
  final DateTime updatedAt;
  final TravelLocationEntity? origin;
  final TravelLocationEntity? destination;
  final TravelRouteEntity? route;
  final List<TravelStopEntity> selectedPointsOfInterest;
  final List<TravelStopEntity> selectedHotels;

  const PlannedTripEntity({
    required this.id,
    required this.title,
    required this.routeSummary,
    required this.note,
    required this.updatedAt,
    this.origin,
    this.destination,
    this.route,
    this.selectedPointsOfInterest = const [],
    this.selectedHotels = const [],
  });

  bool get hasRouteSnapshot =>
      origin != null && destination != null && route != null;
}
