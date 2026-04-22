import 'package:atlas/features/place_details/domain/entities/place_details_entity.dart';
import 'package:atlas/features/place_details/domain/entities/place_review_entity.dart';
import 'package:equatable/equatable.dart';

abstract class PlaceDetailsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PlaceDetailsInitial extends PlaceDetailsState {}

class PlaceDetailsLoading extends PlaceDetailsState {}

class PlaceDetailsLoaded extends PlaceDetailsState {
  final PlaceDetailsEntity place;
  final List<PlaceReviewEntity> communityReviews;

  PlaceDetailsLoaded({required this.place, required this.communityReviews});

  int get totalReviewCount => place.userRatingCount + communityReviews.length;
  List<PlaceReviewEntity> get allReviews => [
    ...communityReviews,
    ...place.googleReviews,
  ];

  @override
  List<Object?> get props => [place, communityReviews];
}

class PlaceDetailsError extends PlaceDetailsState {
  final String message;

  PlaceDetailsError(this.message);

  @override
  List<Object?> get props => [message];
}
