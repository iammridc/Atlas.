import 'package:atlas/features/profile/domain/entities/planned_trip_entity.dart';
import 'package:atlas/features/profile/domain/repositories/profile_repository.dart';
import 'package:atlas/features/travel_planner/domain/entities/travel_location_entity.dart';
import 'package:atlas/features/travel_planner/domain/entities/travel_route_entity.dart';
import 'package:atlas/features/travel_planner/domain/usecases/build_travel_plan_usecase.dart';
import 'package:atlas/features/travel_planner/domain/usecases/search_travel_locations_usecase.dart';
import 'package:atlas/features/travel_planner/presentation/bloc/travel_planner_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

class TravelPlannerCubit extends Cubit<TravelPlannerState> {
  final BuildTravelPlanUseCase _buildTravelPlan;
  final SearchTravelLocationsUseCase _searchLocations;
  final ProfileRepository _profileRepository;

  TravelPlannerCubit({
    required BuildTravelPlanUseCase buildTravelPlan,
    required SearchTravelLocationsUseCase searchLocations,
    required ProfileRepository profileRepository,
    required TravelLocationEntity destination,
  }) : _buildTravelPlan = buildTravelPlan,
       _searchLocations = searchLocations,
       _profileRepository = profileRepository,
       super(TravelPlannerState(destination: destination));

  Future<void> initialize() async {
    emit(
      state.copyWith(
        isResolvingLocation: true,
        errorMessage: '',
        actionStatus: TravelPlannerActionStatus.idle,
        actionMessage: '',
      ),
    );

    final origin = await _resolveCurrentLocation();
    if (origin == null) {
      emit(
        state.copyWith(
          isResolvingLocation: false,
          errorMessage: 'Choose a start point to build routes.',
        ),
      );
      return;
    }

    emit(state.copyWith(origin: origin, isResolvingLocation: false));
    await buildPlan();
  }

  Future<void> buildPlan() async {
    final origin = state.origin;
    if (origin == null) return;

    emit(
      state.copyWith(
        isLoadingPlan: true,
        errorMessage: '',
        actionStatus: TravelPlannerActionStatus.idle,
        actionMessage: '',
      ),
    );

    final result = await _buildTravelPlan(
      origin: origin,
      destination: state.destination,
    );

    result.fold(
      (error) => emit(
        state.copyWith(
          isLoadingPlan: false,
          errorMessage: error.message,
          routes: const [],
          pointsOfInterest: const [],
          hotels: const [],
          clearSelectedRoute: true,
        ),
      ),
      (plan) => emit(
        state.copyWith(
          isLoadingPlan: false,
          origin: plan.origin,
          destination: plan.destination,
          routes: plan.routes,
          pointsOfInterest: plan.pointsOfInterest,
          hotels: plan.hotels,
          selectedRouteId: plan.routes.isEmpty ? null : plan.routes.first.id,
          selectedPointIds: const {},
          selectedHotelIds: const {},
        ),
      ),
    );
  }

  Future<List<TravelLocationEntity>> searchLocations(String query) async {
    final result = await _searchLocations(query);
    return result.fold((_) => const [], (locations) => locations);
  }

  Future<void> setOrigin(TravelLocationEntity origin) async {
    emit(state.copyWith(origin: origin));
    await buildPlan();
  }

  Future<void> setDestination(TravelLocationEntity destination) async {
    emit(state.copyWith(destination: destination));
    await buildPlan();
  }

  void selectRoute(String routeId) {
    emit(state.copyWith(selectedRouteId: routeId));
  }

  void togglePointOfInterest(String id) {
    final selected = Set<String>.of(state.selectedPointIds);
    selected.contains(id) ? selected.remove(id) : selected.add(id);
    emit(state.copyWith(selectedPointIds: selected));
  }

  void toggleHotel(String id) {
    final selected = Set<String>.of(state.selectedHotelIds);
    selected.contains(id) ? selected.remove(id) : selected.add(id);
    emit(state.copyWith(selectedHotelIds: selected));
  }

  Future<void> saveSelectedTrip() async {
    final route = state.selectedRoute;
    final origin = state.origin;
    if (route == null || origin == null) {
      emit(
        state.copyWith(
          actionStatus: TravelPlannerActionStatus.failed,
          actionMessage: 'Choose a route before saving.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        actionStatus: TravelPlannerActionStatus.saving,
        actionMessage: '',
      ),
    );

    final result = await _profileRepository.savePlannedTrip(
      PlannedTripEntity(
        id: '',
        title: 'Trip to ${state.destination.name}',
        routeSummary: _buildRouteSummary(route, origin, state.destination),
        note: _buildTripNote(route),
        updatedAt: DateTime.now(),
      ),
    );

    result.fold(
      (error) => emit(
        state.copyWith(
          actionStatus: TravelPlannerActionStatus.failed,
          actionMessage: error.message,
        ),
      ),
      (_) => emit(
        state.copyWith(
          actionStatus: TravelPlannerActionStatus.saved,
          actionMessage: 'Trip saved to Planned Trips.',
        ),
      ),
    );
  }

  String _buildRouteSummary(
    TravelRouteEntity route,
    TravelLocationEntity origin,
    TravelLocationEntity destination,
  ) {
    final price = route.priceLabel == null ? '' : ' · ${route.priceLabel}';
    return '${origin.name} -> ${destination.name} · ${route.durationLabel}$price';
  }

  String _buildTripNote(TravelRouteEntity route) {
    final buffer = StringBuffer()
      ..writeln(
        route.isMocked
            ? 'Mock flight route'
            : route.isEstimated
            ? 'Estimated route'
            : 'Google route',
      )
      ..writeln('Transport: ${route.transportType.name}')
      ..writeln('Transfers: ${route.transferCount}')
      ..writeln();

    for (final leg in route.legs) {
      buffer.writeln(
        '- ${leg.title}: ${leg.fromName} -> ${leg.toName} (${_formatDuration(leg.duration)})',
      );
    }

    if (state.selectedPointsOfInterest.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Places to visit:');
      for (final point in state.selectedPointsOfInterest) {
        buffer.writeln('- ${point.name}');
      }
    }

    if (state.selectedHotels.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Hotels:');
      for (final hotel in state.selectedHotels) {
        buffer.writeln('- ${hotel.name}');
      }
    }

    return buffer.toString().trim();
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    }
    return '${duration.inMinutes}m';
  }

  Future<TravelLocationEntity?> _resolveCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      final reverseGeocodeResult = await _searchLocations.reverseGeocode(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      final resolvedLocation = reverseGeocodeResult.fold(
        (_) => null,
        (location) => location,
      );
      if (resolvedLocation != null) return resolvedLocation;

      return TravelLocationEntity(
        id: 'current-location',
        name: 'Current location',
        address: 'Current location',
        city: '',
        country: '',
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      return null;
    }
  }
}
