import 'package:atlas/core/errors/app_exception.dart';
import 'package:atlas/features/place_details/domain/entities/place_review_entity.dart';
import 'package:atlas/features/place_details/domain/repositories/place_details_repository.dart';
import 'package:dartz/dartz.dart';

class GetPlaceCommunityReviewsUseCase {
  final PlaceDetailsRepository _repository;

  GetPlaceCommunityReviewsUseCase(this._repository);

  Future<Either<AppException, List<PlaceReviewEntity>>> call(String placeId) {
    return _repository.getCommunityReviews(placeId);
  }
}
