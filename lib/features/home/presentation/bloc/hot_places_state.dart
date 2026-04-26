import 'package:atlas/features/home/domain/entity/recommendation_entity.dart';

abstract class HotPlacesState {}

class HotPlacesInitial extends HotPlacesState {}

class HotPlacesLoading extends HotPlacesState {}

class HotPlacesLoaded extends HotPlacesState {
  final List<RecommendationEntity> places;

  HotPlacesLoaded({required this.places});
}

class HotPlacesError extends HotPlacesState {
  final String message;
  final bool isReloading;

  HotPlacesError(this.message, {this.isReloading = false});
}
