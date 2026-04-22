import 'package:atlas/core/errors/app_exception.dart';
import 'package:atlas/features/place_details/domain/entities/place_details_entity.dart';
import 'package:atlas/features/place_details/domain/repositories/place_details_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class GetPlaceDetailsUseCase {
  final PlaceDetailsRepository _repository;

  GetPlaceDetailsUseCase(this._repository);

  Future<Either<AppException, PlaceDetailsEntity>> call(
    GetPlaceDetailsParams params,
  ) {
    return _repository.getPlaceDetails(
      placeId: params.placeId,
      fallbackName: params.fallbackName,
      fallbackCity: params.fallbackCity,
      fallbackCountry: params.fallbackCountry,
      fallbackPhotoName: params.fallbackPhotoName,
    );
  }
}

class GetPlaceDetailsParams extends Equatable {
  final String placeId;
  final String fallbackName;
  final String fallbackCity;
  final String fallbackCountry;
  final String? fallbackPhotoName;

  const GetPlaceDetailsParams({
    required this.placeId,
    required this.fallbackName,
    required this.fallbackCity,
    required this.fallbackCountry,
    this.fallbackPhotoName,
  });

  @override
  List<Object?> get props => [
    placeId,
    fallbackName,
    fallbackCity,
    fallbackCountry,
    fallbackPhotoName,
  ];
}
