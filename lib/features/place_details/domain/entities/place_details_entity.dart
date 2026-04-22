import 'package:atlas/features/place_details/domain/entities/place_review_entity.dart';

class PlaceDetailsEntity {
  final String id;
  final String name;
  final String formattedAddress;
  final String city;
  final String country;
  final String? description;
  final double? rating;
  final int userRatingCount;
  final List<String> photoNames;
  final List<String> categories;
  final List<String> openingHours;
  final String? phoneNumber;
  final String? websiteUri;
  final List<PlaceReviewEntity> googleReviews;

  const PlaceDetailsEntity({
    required this.id,
    required this.name,
    required this.formattedAddress,
    required this.city,
    required this.country,
    required this.userRatingCount,
    required this.photoNames,
    required this.categories,
    required this.openingHours,
    required this.googleReviews,
    this.description,
    this.rating,
    this.phoneNumber,
    this.websiteUri,
  });
}
