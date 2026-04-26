import 'package:atlas/features/home/domain/entity/recommendation_entity.dart';

class RecommendationModel extends RecommendationEntity {
  const RecommendationModel({
    required super.id,
    required super.name,
    required super.city,
    required super.country,
    super.photoReference,
  });

  factory RecommendationModel.fromJson(Map<String, dynamic> json) {
    final photos = json['photos'] as List?;
    final addressComponents = json['addressComponents'] as List<dynamic>? ?? [];

    String city = '';
    String country = '';

    for (final component in addressComponents) {
      final types = List<String>.from(component['types'] ?? []);
      final name = component['longText'] as String? ?? '';

      if (types.contains('locality') ||
          types.contains('administrative_area_level_1')) {
        if (city.isEmpty) city = name;
      }

      if (types.contains('country')) {
        country = name;
      }
    }

    return RecommendationModel(
      id: json['id'] ?? '',
      name: json['displayName']?['text'] ?? '',
      city: city,
      country: country,
      photoReference: photos != null && photos.isNotEmpty
          ? photos.first['name'] as String?
          : null,
    );
  }

  factory RecommendationModel.fromFavoriteJson(
    String id,
    Map<String, dynamic> json,
  ) {
    return RecommendationModel(
      id: id,
      name: (json['name'] as String?)?.trim() ?? '',
      city: (json['city'] as String?)?.trim() ?? '',
      country: (json['country'] as String?)?.trim() ?? '',
      photoReference: (json['photoReference'] as String?)?.trim(),
    );
  }

  factory RecommendationModel.fromHotLikeJson(Map<String, dynamic> json) {
    return RecommendationModel(
      id: (json['placeId'] as String?)?.trim() ?? '',
      name: (json['name'] as String?)?.trim() ?? '',
      city: (json['city'] as String?)?.trim() ?? '',
      country: (json['country'] as String?)?.trim() ?? '',
      photoReference: (json['photoReference'] as String?)?.trim(),
    );
  }
}
