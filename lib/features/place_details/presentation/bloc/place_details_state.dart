import 'package:atlas/features/place_details/domain/entities/place_details_entity.dart';
import 'package:atlas/features/place_details/domain/entities/place_review_entity.dart';
import 'package:atlas/features/profile/domain/entities/profile_review_entity.dart';
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
  final ProfileReviewEntity? currentUserReview;
  final bool isFavorite;
  final bool isSavingFavorite;

  PlaceDetailsLoaded({
    required this.place,
    required this.communityReviews,
    this.currentUserReview,
    this.isFavorite = false,
    this.isSavingFavorite = false,
  });

  int get totalReviewCount => place.userRatingCount + communityReviews.length;
  bool get hasCurrentUserReview => currentUserReview != null;
  List<PlaceReviewEntity> get allReviews => [
    ...communityReviews,
    ...place.googleReviews,
  ];

  PlaceDetailsLoaded copyWith({
    PlaceDetailsEntity? place,
    List<PlaceReviewEntity>? communityReviews,
    ProfileReviewEntity? currentUserReview,
    bool clearCurrentUserReview = false,
    bool? isFavorite,
    bool? isSavingFavorite,
  }) {
    return PlaceDetailsLoaded(
      place: place ?? this.place,
      communityReviews: communityReviews ?? this.communityReviews,
      currentUserReview: clearCurrentUserReview
          ? null
          : (currentUserReview ?? this.currentUserReview),
      isFavorite: isFavorite ?? this.isFavorite,
      isSavingFavorite: isSavingFavorite ?? this.isSavingFavorite,
    );
  }

  @override
  List<Object?> get props => [
    place,
    communityReviews,
    currentUserReview,
    isFavorite,
    isSavingFavorite,
  ];
}

class PlaceDetailsError extends PlaceDetailsState {
  final String message;

  PlaceDetailsError(this.message);

  @override
  List<Object?> get props => [message];
}
