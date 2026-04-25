import 'package:atlas/features/travel_planner/domain/entities/travel_location_entity.dart';
import 'package:atlas/features/travel_planner/domain/entities/travel_route_entity.dart';
import 'package:equatable/equatable.dart';

enum TravelPlannerActionStatus { idle, saving, saved, failed }

class TravelPlannerState extends Equatable {
  final TravelLocationEntity? origin;
  final TravelLocationEntity destination;
  final bool isResolvingLocation;
  final bool isLoadingPlan;
  final String errorMessage;
  final List<TravelRouteEntity> routes;
  final List<TravelStopEntity> pointsOfInterest;
  final List<TravelStopEntity> hotels;
  final String? selectedRouteId;
  final Set<String> selectedPointIds;
  final Set<String> selectedHotelIds;
  final TravelPlannerActionStatus actionStatus;
  final String actionMessage;

  const TravelPlannerState({
    required this.destination,
    this.origin,
    this.isResolvingLocation = false,
    this.isLoadingPlan = false,
    this.errorMessage = '',
    this.routes = const [],
    this.pointsOfInterest = const [],
    this.hotels = const [],
    this.selectedRouteId,
    this.selectedPointIds = const {},
    this.selectedHotelIds = const {},
    this.actionStatus = TravelPlannerActionStatus.idle,
    this.actionMessage = '',
  });

  TravelRouteEntity? get selectedRoute {
    for (final route in routes) {
      if (route.id == selectedRouteId) return route;
    }
    return routes.isEmpty ? null : routes.first;
  }

  List<TravelStopEntity> get selectedPointsOfInterest => pointsOfInterest
      .where((point) => selectedPointIds.contains(point.id))
      .toList();

  List<TravelStopEntity> get selectedHotels =>
      hotels.where((hotel) => selectedHotelIds.contains(hotel.id)).toList();

  TravelPlannerState copyWith({
    TravelLocationEntity? origin,
    bool clearOrigin = false,
    TravelLocationEntity? destination,
    bool? isResolvingLocation,
    bool? isLoadingPlan,
    String? errorMessage,
    List<TravelRouteEntity>? routes,
    List<TravelStopEntity>? pointsOfInterest,
    List<TravelStopEntity>? hotels,
    String? selectedRouteId,
    bool clearSelectedRoute = false,
    Set<String>? selectedPointIds,
    Set<String>? selectedHotelIds,
    TravelPlannerActionStatus? actionStatus,
    String? actionMessage,
  }) {
    return TravelPlannerState(
      destination: destination ?? this.destination,
      origin: clearOrigin ? null : origin ?? this.origin,
      isResolvingLocation: isResolvingLocation ?? this.isResolvingLocation,
      isLoadingPlan: isLoadingPlan ?? this.isLoadingPlan,
      errorMessage: errorMessage ?? this.errorMessage,
      routes: routes ?? this.routes,
      pointsOfInterest: pointsOfInterest ?? this.pointsOfInterest,
      hotels: hotels ?? this.hotels,
      selectedRouteId: clearSelectedRoute
          ? null
          : selectedRouteId ?? this.selectedRouteId,
      selectedPointIds: selectedPointIds ?? this.selectedPointIds,
      selectedHotelIds: selectedHotelIds ?? this.selectedHotelIds,
      actionStatus: actionStatus ?? this.actionStatus,
      actionMessage: actionMessage ?? this.actionMessage,
    );
  }

  @override
  List<Object?> get props => [
    origin,
    destination,
    isResolvingLocation,
    isLoadingPlan,
    errorMessage,
    routes,
    pointsOfInterest,
    hotels,
    selectedRouteId,
    selectedPointIds,
    selectedHotelIds,
    actionStatus,
    actionMessage,
  ];
}
