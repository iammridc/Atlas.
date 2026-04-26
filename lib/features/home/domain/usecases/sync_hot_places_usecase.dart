import 'package:atlas/features/home/domain/repositories/recommendations_repository.dart';

class SyncHotPlacesUseCase {
  final RecommendationsRepository _repository;

  SyncHotPlacesUseCase(this._repository);

  Future<void> call() {
    return _repository.syncCurrentUserFavoritesToHotPlaces();
  }
}
