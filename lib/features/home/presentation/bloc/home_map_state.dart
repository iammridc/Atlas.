import 'package:atlas/features/home/domain/entity/home_map_entity.dart';
import 'package:atlas/features/home/domain/entity/recommendation_entity.dart';

enum HomeMapStatus {
  initial,
  locating,
  loadingNearby,
  inspectingPlace,
  ready,
  error,
}

class HomeMapState {
  final HomeMapCoordinateEntity? currentLocation;
  final HomeMapLocationEntity? currentPlace;
  final HomeMapLocationEntity? cameraPlace;
  final List<RecommendationEntity> nearbyPlaces;
  final RecommendationEntity? selectedPlace;
  final HomeMapStatus status;
  final String? errorMessage;

  const HomeMapState({
    this.currentLocation,
    this.currentPlace,
    this.cameraPlace,
    this.nearbyPlaces = const [],
    this.selectedPlace,
    this.status = HomeMapStatus.initial,
    this.errorMessage,
  });

  bool get hasLocation => currentLocation != null;
  bool get isLoading =>
      status == HomeMapStatus.locating ||
      status == HomeMapStatus.loadingNearby ||
      status == HomeMapStatus.inspectingPlace;

  HomeMapState copyWith({
    HomeMapCoordinateEntity? currentLocation,
    HomeMapLocationEntity? currentPlace,
    HomeMapLocationEntity? cameraPlace,
    List<RecommendationEntity>? nearbyPlaces,
    RecommendationEntity? selectedPlace,
    HomeMapStatus? status,
    String? errorMessage,
    bool clearCurrentPlace = false,
    bool clearCameraPlace = false,
    bool clearSelectedPlace = false,
    bool clearError = false,
  }) {
    return HomeMapState(
      currentLocation: currentLocation ?? this.currentLocation,
      currentPlace: clearCurrentPlace
          ? null
          : currentPlace ?? this.currentPlace,
      cameraPlace: clearCameraPlace ? null : cameraPlace ?? this.cameraPlace,
      nearbyPlaces: nearbyPlaces ?? this.nearbyPlaces,
      selectedPlace: clearSelectedPlace
          ? null
          : selectedPlace ?? this.selectedPlace,
      status: status ?? this.status,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
