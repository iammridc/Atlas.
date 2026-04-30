import 'package:atlas/features/profile/domain/entities/profile_review_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileReviewModel extends ProfileReviewEntity {
  const ProfileReviewModel({
    required super.id,
    super.placeId,
    required super.placeName,
    super.placeCity,
    super.placeCountry,
    super.photoReference,
    required super.rating,
    required super.text,
    super.likedTags,
    super.photoDataUrls,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ProfileReviewModel.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return ProfileReviewModel.fromJson(doc.data(), id: doc.id);
  }

  factory ProfileReviewModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return ProfileReviewModel.fromJson(doc.data() ?? const {}, id: doc.id);
  }

  factory ProfileReviewModel.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    return ProfileReviewModel(
      id: id,
      placeId: (json['placeId'] as String?)?.trim() ?? '',
      placeName: (json['placeName'] as String?)?.trim() ?? '',
      placeCity: (json['placeCity'] as String?)?.trim() ?? '',
      placeCountry: (json['placeCountry'] as String?)?.trim() ?? '',
      photoReference: _nullableString(json['photoReference']),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      text: (json['text'] as String?)?.trim() ?? '',
      likedTags: _stringList(json['likedTags']),
      photoDataUrls: _stringList(json['photoDataUrls']),
      createdAt: _parseDate(json['createdAt'] ?? json['updatedAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'placeId': placeId.trim(),
      'placeName': placeName.trim(),
      'placeCity': placeCity.trim(),
      'placeCountry': placeCountry.trim(),
      'photoReference': photoReference?.trim(),
      'rating': rating,
      'text': text.trim(),
      'likedTags': likedTags
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList(),
      'photoDataUrls': photoDataUrls
          .map((photo) => photo.trim())
          .where((photo) => photo.isNotEmpty)
          .toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static String? _nullableString(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
