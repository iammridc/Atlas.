import 'dart:async';
import 'dart:math';

import 'package:atlas/core/services/location_service.dart';
import 'package:atlas/features/home/domain/entity/home_map_entity.dart';
import 'package:atlas/features/home/domain/entity/recommendation_entity.dart';
import 'package:atlas/features/home/domain/repositories/home_map_repository.dart';
import 'package:atlas/features/home/domain/usecases/get_nearby_map_places_usecase.dart';
import 'package:atlas/features/home/presentation/bloc/home_map_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

class HomeMapCubit extends Cubit<HomeMapState> {
  static const double _mapPickSearchRadiusMeters = 30;

  final GetNearbyMapPlacesUseCase _getNearbyPlaces;
  final FindNearestMapPlaceUseCase _findNearestPlace;
  final ResolveHomeMapLocationUseCase _resolveLocation;
  final LocationService _locationService;
  int _activeRequestId = 0;
  int _activeInspectionRequestId = 0;

  HomeMapCubit({
    GetNearbyMapPlacesUseCase? getNearbyPlaces,
    FindNearestMapPlaceUseCase? findNearestPlace,
    ResolveHomeMapLocationUseCase? resolveLocation,
    LocationService? locationService,
  }) : _getNearbyPlaces = getNearbyPlaces ?? _resolveNearbyPlacesUseCase(),
       _findNearestPlace = findNearestPlace ?? _resolveNearestPlaceUseCase(),
       _resolveLocation = resolveLocation ?? _resolveLocationUseCase(),
       _locationService = locationService ?? GetIt.I<LocationService>(),
       super(const HomeMapState());

  static GetNearbyMapPlacesUseCase _resolveNearbyPlacesUseCase() {
    if (GetIt.I.isRegistered<GetNearbyMapPlacesUseCase>()) {
      return GetIt.I<GetNearbyMapPlacesUseCase>();
    }

    return GetNearbyMapPlacesUseCase(GetIt.I<HomeMapRepository>());
  }

  static FindNearestMapPlaceUseCase _resolveNearestPlaceUseCase() {
    if (GetIt.I.isRegistered<FindNearestMapPlaceUseCase>()) {
      return GetIt.I<FindNearestMapPlaceUseCase>();
    }

    return FindNearestMapPlaceUseCase(GetIt.I<HomeMapRepository>());
  }

  static ResolveHomeMapLocationUseCase _resolveLocationUseCase() {
    if (GetIt.I.isRegistered<ResolveHomeMapLocationUseCase>()) {
      return GetIt.I<ResolveHomeMapLocationUseCase>();
    }

    return ResolveHomeMapLocationUseCase(GetIt.I<HomeMapRepository>());
  }

  Future<void> loadCurrentLocation({bool includeNearbyPlaces = false}) async {
    final requestId = ++_activeRequestId;

    emit(
      state.copyWith(
        status: HomeMapStatus.locating,
        clearError: true,
        clearCurrentPlace: true,
        clearSelectedPlace: true,
      ),
    );

    final currentLocation = await _locationService.getCurrentLocation();
    if (isClosed || requestId != _activeRequestId) return;

    if (currentLocation == null) {
      emit(
        state.copyWith(
          status: HomeMapStatus.error,
          errorMessage: 'Enable location access to show your map.',
        ),
      );
      return;
    }

    final coordinate = HomeMapCoordinateEntity(
      latitude: currentLocation.latitude,
      longitude: currentLocation.longitude,
    );

    emit(
      state.copyWith(
        currentLocation: coordinate,
        status: includeNearbyPlaces
            ? HomeMapStatus.loadingNearby
            : HomeMapStatus.ready,
        clearError: true,
        clearCurrentPlace: true,
      ),
    );

    unawaited(_resolveCurrentLocationName(coordinate, requestId));

    if (includeNearbyPlaces) {
      await loadNearbyPlaces(center: coordinate, requestId: requestId);
    }
  }

  Future<void> _resolveCurrentLocationName(
    HomeMapCoordinateEntity coordinate,
    int requestId,
  ) async {
    final result = await _resolveLocation(center: coordinate);
    if (isClosed || requestId != _activeRequestId) return;

    result.fold((_) {}, (location) {
      if (location == null || !location.hasLocationLabel) return;
      emit(state.copyWith(currentPlace: location, clearError: true));
    });
  }

  Future<void> loadNearbyPlaces({
    HomeMapCoordinateEntity? center,
    int? requestId,
  }) async {
    final effectiveRequestId = requestId ?? ++_activeRequestId;
    final effectiveCenter = center ?? state.currentLocation;
    if (effectiveCenter == null) {
      await loadCurrentLocation(includeNearbyPlaces: true);
      return;
    }

    emit(state.copyWith(status: HomeMapStatus.loadingNearby, clearError: true));

    final result = await _getNearbyPlaces(center: effectiveCenter);
    if (isClosed || effectiveRequestId != _activeRequestId) return;

    result.fold(
      (exception) => emit(
        state.copyWith(
          status: HomeMapStatus.error,
          errorMessage: exception.message,
        ),
      ),
      (places) => emit(
        state.copyWith(
          nearbyPlaces: places,
          status: HomeMapStatus.ready,
          clearError: true,
        ),
      ),
    );
  }

  void selectPlace(RecommendationEntity place) {
    _activeInspectionRequestId++;
    emit(
      state.copyWith(
        selectedPlace: place,
        status: HomeMapStatus.ready,
        clearError: true,
      ),
    );
  }

  Future<void> inspectMapPoint(HomeMapCoordinateEntity point) async {
    final existingPlace = _nearestLoadedPlace(
      point,
      radiusMeters: _mapPickSearchRadiusMeters,
    );
    if (existingPlace != null) {
      selectPlace(existingPlace);
      return;
    }

    final requestId = ++_activeInspectionRequestId;
    emit(
      state.copyWith(status: HomeMapStatus.inspectingPlace, clearError: true),
    );

    final result = await _findNearestPlace(
      center: point,
      radiusMeters: _mapPickSearchRadiusMeters,
    );
    if (isClosed || requestId != _activeInspectionRequestId) return;

    result.fold(
      (exception) => emit(
        state.copyWith(
          status: HomeMapStatus.error,
          errorMessage: exception.message,
        ),
      ),
      (place) {
        if (place == null) {
          emit(
            state.copyWith(
              status: HomeMapStatus.ready,
              errorMessage: 'No place information found here.',
              clearSelectedPlace: true,
            ),
          );
          return;
        }

        final updatedPlaces = _mergePlace(state.nearbyPlaces, place);
        emit(
          state.copyWith(
            nearbyPlaces: updatedPlaces,
            selectedPlace: place,
            status: HomeMapStatus.ready,
            clearError: true,
          ),
        );
      },
    );
  }

  void clearSelection() {
    _activeInspectionRequestId++;
    emit(state.copyWith(status: HomeMapStatus.ready, clearSelectedPlace: true));
  }

  RecommendationEntity? _nearestLoadedPlace(
    HomeMapCoordinateEntity point, {
    required double radiusMeters,
  }) {
    RecommendationEntity? nearestPlace;
    var nearestDistance = double.infinity;

    for (final place in state.nearbyPlaces) {
      if (!place.hasCoordinates) continue;
      final distance = _distanceMeters(
        point.latitude,
        point.longitude,
        place.latitude!,
        place.longitude!,
      );

      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestPlace = place;
      }
    }

    return nearestDistance <= radiusMeters ? nearestPlace : null;
  }

  List<RecommendationEntity> _mergePlace(
    List<RecommendationEntity> places,
    RecommendationEntity place,
  ) {
    final index = places.indexWhere((item) => item.id == place.id);
    if (index == -1) return [...places, place];

    final updatedPlaces = [...places];
    updatedPlaces[index] = place;
    return updatedPlaces;
  }

  double _distanceMeters(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    const earthRadius = 6371000.0;
    final dLat = _degreesToRadians(endLatitude - startLatitude);
    final dLng = _degreesToRadians(endLongitude - startLongitude);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(startLatitude)) *
            cos(_degreesToRadians(endLatitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) => degrees * pi / 180;
}
