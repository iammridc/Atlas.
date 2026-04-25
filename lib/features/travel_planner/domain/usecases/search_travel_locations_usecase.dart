import 'package:atlas/core/errors/app_exception.dart';
import 'package:atlas/features/travel_planner/domain/entities/travel_location_entity.dart';
import 'package:atlas/features/travel_planner/domain/repositories/travel_planner_repository.dart';
import 'package:dartz/dartz.dart';

class SearchTravelLocationsUseCase {
  final TravelPlannerRepository _repository;

  SearchTravelLocationsUseCase(this._repository);

  Future<Either<AppException, List<TravelLocationEntity>>> call(String query) {
    return _repository.searchLocations(query);
  }

  Future<Either<AppException, TravelLocationEntity?>> reverseGeocode({
    required double latitude,
    required double longitude,
  }) {
    return _repository.reverseGeocodeLocation(
      latitude: latitude,
      longitude: longitude,
    );
  }
}
