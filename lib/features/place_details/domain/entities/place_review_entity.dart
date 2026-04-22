enum PlaceReviewSource { google, community }

class PlaceReviewEntity {
  final String authorName;
  final String? authorSubtitle;
  final String text;
  final double rating;
  final String? relativeTimeDescription;
  final DateTime? publishedAt;
  final String? profilePhotoUrl;
  final PlaceReviewSource source;

  const PlaceReviewEntity({
    required this.authorName,
    required this.text,
    required this.rating,
    required this.source,
    this.authorSubtitle,
    this.relativeTimeDescription,
    this.publishedAt,
    this.profilePhotoUrl,
  });
}
