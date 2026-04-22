import 'package:atlas/core/errors/app_exception.dart';
import 'package:atlas/features/place_details/domain/entities/place_details_entity.dart';
import 'package:atlas/features/place_details/domain/entities/place_review_entity.dart';
import 'package:dartz/dartz.dart';

abstract class PlaceDetailsRepository {
  Future<Either<AppException, PlaceDetailsEntity>> getPlaceDetails({
    required String placeId,
    required String fallbackName,
    required String fallbackCity,
    required String fallbackCountry,
    String? fallbackPhotoName,
  });

  Future<Either<AppException, List<PlaceReviewEntity>>> getCommunityReviews(
    String placeId,
  );
}
