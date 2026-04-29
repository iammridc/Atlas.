class ProfileReviewEntity {
  final String id;
  final String placeId;
  final String placeName;
  final String placeCity;
  final String placeCountry;
  final double rating;
  final String text;
  final List<String> likedTags;
  final List<String> photoDataUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProfileReviewEntity({
    required this.id,
    this.placeId = '',
    required this.placeName,
    this.placeCity = '',
    this.placeCountry = '',
    required this.rating,
    required this.text,
    this.likedTags = const [],
    this.photoDataUrls = const [],
    required this.createdAt,
    required this.updatedAt,
  });
}
