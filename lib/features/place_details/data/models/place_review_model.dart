import 'package:atlas/features/place_details/domain/entities/place_review_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlaceReviewModel extends PlaceReviewEntity {
  const PlaceReviewModel({
    required super.authorName,
    required super.text,
    required super.rating,
    required super.source,
    super.authorSubtitle,
    super.relativeTimeDescription,
    super.publishedAt,
    super.profilePhotoUrl,
  });

  factory PlaceReviewModel.fromGoogleJson(Map<String, dynamic> json) {
    final author = json['authorAttribution'] as Map<String, dynamic>? ?? {};
    final textData = json['text'] as Map<String, dynamic>? ?? {};

    return PlaceReviewModel(
      authorName: author['displayName'] as String? ?? 'Google user',
      text: textData['text'] as String? ?? '',
      rating: _toDouble(json['rating']),
      relativeTimeDescription:
          json['relativePublishTimeDescription'] as String?,
      publishedAt: _parseDateTime(json['publishTime']),
      profilePhotoUrl: author['photoUri'] as String?,
      source: PlaceReviewSource.google,
    );
  }

  factory PlaceReviewModel.fromCommunityJson(Map<String, dynamic> json) {
    final placesVisited = json['placesVisited'];
    final authorSubtitle =
        json['authorSubtitle'] as String? ??
        (placesVisited is num
            ? 'Traveler, ${placesVisited.toInt()} places visited'
            : null);

    return PlaceReviewModel(
      authorName:
          json['authorName'] as String? ??
          json['userName'] as String? ??
          'Atlas traveler',
      authorSubtitle: authorSubtitle,
      text:
          json['text'] as String? ??
          json['reviewText'] as String? ??
          'No review text provided yet.',
      rating: _toDouble(json['rating'], fallback: 0),
      relativeTimeDescription: json['relativeTimeDescription'] as String?,
      publishedAt: _parseDateTime(json['createdAt'] ?? json['publishedAt']),
      profilePhotoUrl:
          json['profilePhotoUrl'] as String? ?? json['avatarUrl'] as String?,
      source: PlaceReviewSource.community,
    );
  }

  static double _toDouble(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
