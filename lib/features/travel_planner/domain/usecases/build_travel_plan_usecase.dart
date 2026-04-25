import 'package:atlas/core/errors/app_exception.dart';
import 'package:atlas/features/travel_planner/domain/entities/travel_location_entity.dart';
import 'package:atlas/features/travel_planner/domain/entities/travel_route_entity.dart';
import 'package:atlas/features/travel_planner/domain/repositories/travel_planner_repository.dart';
import 'package:dartz/dartz.dart';

class BuildTravelPlanUseCase {
  final TravelPlannerRepository _repository;

  BuildTravelPlanUseCase(this._repository);

  Future<Either<AppException, TravelRoutePlanEntity>> call({
    required TravelLocationEntity origin,
    required TravelLocationEntity destination,
  }) {
    return _repository.buildPlan(origin: origin, destination: destination);
  }
}
