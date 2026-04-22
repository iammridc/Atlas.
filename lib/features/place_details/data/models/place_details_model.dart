import 'package:atlas/features/place_details/data/models/place_review_model.dart';
import 'package:atlas/features/place_details/domain/entities/place_details_entity.dart';
import 'package:atlas/features/place_details/domain/entities/place_review_entity.dart';

class PlaceDetailsModel extends PlaceDetailsEntity {
  const PlaceDetailsModel({
    required super.id,
    required super.name,
    required super.formattedAddress,
    required super.city,
    required super.country,
    required super.userRatingCount,
    required super.photoNames,
    required super.categories,
    required super.openingHours,
    required super.googleReviews,
    super.description,
    super.rating,
    super.phoneNumber,
    super.websiteUri,
  });

  factory PlaceDetailsModel.fromJson(
    Map<String, dynamic> json, {
    required String fallbackName,
    required String fallbackCity,
    required String fallbackCountry,
    String? fallbackPhotoName,
    List<String>? resolvedPhotoSources,
  }) {
    final displayName = json['displayName'] as Map<String, dynamic>? ?? {};
    final editorialSummary =
        json['editorialSummary'] as Map<String, dynamic>? ?? {};
    final regularOpeningHours =
        json['regularOpeningHours'] as Map<String, dynamic>? ?? {};
    final photos = json['photos'] as List<dynamic>? ?? [];
    final reviews = json['reviews'] as List<dynamic>? ?? [];
    final addressComponents =
        json['addressComponents'] as List<dynamic>? ?? const [];

    final parsedCity = _extractCity(addressComponents) ?? fallbackCity;
    final parsedCountry = _extractCountry(addressComponents) ?? fallbackCountry;
    final seenPhotoNames = <String>{};
    final photoNames = photos
        .map((photo) => (photo as Map<String, dynamic>)['name'] as String?)
        .whereType<String>()
        .where((photoName) => seenPhotoNames.add(photoName))
        .toList();

    final safePhotoNames =
        (resolvedPhotoSources != null && resolvedPhotoSources.isNotEmpty)
        ? resolvedPhotoSources
        : photoNames.isNotEmpty
        ? photoNames
        : [
            if (fallbackPhotoName != null && fallbackPhotoName.isNotEmpty)
              fallbackPhotoName,
          ];

    return PlaceDetailsModel(
      id: json['id'] as String? ?? '',
      name: displayName['text'] as String? ?? fallbackName,
      formattedAddress:
          json['formattedAddress'] as String? ??
          _buildFallbackAddress(parsedCity, parsedCountry),
      city: parsedCity,
      country: parsedCountry,
      description: editorialSummary['text'] as String?,
      rating: _toDoubleOrNull(json['rating']),
      userRatingCount: _toInt(json['userRatingCount']),
      photoNames: safePhotoNames,
      categories: _extractCategories(json),
      openingHours: List<String>.from(
        regularOpeningHours['weekdayDescriptions'] ?? [],
      ),
      phoneNumber: json['nationalPhoneNumber'] as String?,
      websiteUri: json['websiteUri'] as String?,
      googleReviews: reviews
          .take(3)
          .map(
            (review) =>
                PlaceReviewModel.fromGoogleJson(review as Map<String, dynamic>),
          )
          .where((review) => review.text.trim().isNotEmpty)
          .cast<PlaceReviewEntity>()
          .toList(),
    );
  }

  static String _buildFallbackAddress(String city, String country) {
    if (city.isEmpty && country.isEmpty) {
      return 'Address unavailable';
    }
    if (city.isEmpty) return country;
    if (country.isEmpty) return city;
    return '$city, $country';
  }

  static String? _extractCity(List<dynamic> components) {
    for (final component in components) {
      final json = component as Map<String, dynamic>;
      final types = List<String>.from(json['types'] ?? []);
      final value = json['longText'] as String?;
      if (value == null || value.isEmpty) continue;
      if (types.contains('locality') ||
          types.contains('administrative_area_level_1')) {
        return value;
      }
    }
    return null;
  }

  static String? _extractCountry(List<dynamic> components) {
    for (final component in components) {
      final json = component as Map<String, dynamic>;
      final types = List<String>.from(json['types'] ?? []);
      final value = json['longText'] as String?;
      if (value == null || value.isEmpty) continue;
      if (types.contains('country')) {
        return value;
      }
    }
    return null;
  }

  static List<String> _extractCategories(Map<String, dynamic> json) {
    final primaryTypeDisplayName =
        (json['primaryTypeDisplayName'] as Map<String, dynamic>?)?['text']
            as String?;
    final types = List<String>.from(json['types'] ?? []);

    final formattedTypes = [
      if (primaryTypeDisplayName != null && primaryTypeDisplayName.isNotEmpty)
        _normalizeDisplayLabel(primaryTypeDisplayName),
      ...types
          .where(
            (type) =>
                type != 'point_of_interest' &&
                type != 'establishment' &&
                type != 'political' &&
                type != 'premise',
          )
          .map(_formatTypeLabel),
    ];

    final seen = <String>{};
    return formattedTypes
        .where((type) => seen.add(_normalizedCategoryKey(type)))
        .take(4)
        .toList();
  }

  static String _formatTypeLabel(String value) {
    return _normalizeDisplayLabel(
      value
          .split('_')
          .map(
            (part) => part.isEmpty
                ? part
                : '${part[0].toUpperCase()}${part.substring(1)}',
          )
          .join(' '),
    );
  }

  static String _normalizeDisplayLabel(String value) {
    return value
        .trim()
        .split(RegExp(r'\s+'))
        .map((part) {
          if (part.isEmpty) return part;
          return '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}';
        })
        .join(' ');
  }

  static String _normalizedCategoryKey(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  static double? _toDoubleOrNull(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
