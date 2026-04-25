import 'package:atlas/core/errors/app_exception.dart';
import 'package:atlas/features/place_details/data/models/place_details_model.dart';
import 'package:atlas/features/place_details/data/models/place_review_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract class PlaceDetailsRemoteDatasource {
  Future<PlaceDetailsModel> getPlaceDetails({
    required String placeId,
    required String fallbackName,
    required String fallbackCity,
    required String fallbackCountry,
    String? fallbackPhotoName,
  });

  Future<List<PlaceReviewModel>> getCommunityReviews(String placeId);
}

class PlaceDetailsRemoteDatasourceImpl implements PlaceDetailsRemoteDatasource {
  final Dio _dio;
  final FirebaseFirestore _firestore;

  static const _baseUrl = 'https://places.googleapis.com/v1/places';
  static const _fieldMask =
      'id,'
      'displayName,'
      'primaryTypeDisplayName,'
      'formattedAddress,'
      'location,'
      'addressComponents,'
      'editorialSummary,'
      'rating,'
      'userRatingCount,'
      'photos,'
      'types,'
      'reviews,'
      'regularOpeningHours.weekdayDescriptions,'
      'nationalPhoneNumber,'
      'websiteUri';

  PlaceDetailsRemoteDatasourceImpl({
    required Dio dio,
    required FirebaseFirestore firestore,
  }) : _dio = dio,
       _firestore = firestore;

  String get _apiKey => dotenv.env['GOOGLE_API_KEY'] ?? '';

  @override
  Future<PlaceDetailsModel> getPlaceDetails({
    required String placeId,
    required String fallbackName,
    required String fallbackCity,
    required String fallbackCountry,
    String? fallbackPhotoName,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/$placeId',
        options: Options(
          headers: {'X-Goog-Api-Key': _apiKey, 'X-Goog-FieldMask': _fieldMask},
        ),
      );

      final responseJson = response.data as Map<String, dynamic>;
      final resolvedPhotoSources = await _resolvePhotoSources(responseJson);

      return PlaceDetailsModel.fromJson(
        responseJson,
        fallbackName: fallbackName,
        fallbackCity: fallbackCity,
        fallbackCountry: fallbackCountry,
        fallbackPhotoName: fallbackPhotoName,
        resolvedPhotoSources: resolvedPhotoSources,
      );
    } on DioException catch (e) {
      throw ServerException(
        message:
            e.response?.data?['error']?['message'] ??
            'Failed to load this place.',
      );
    } catch (e) {
      throw ServerException(message: 'Failed to load this place.');
    }
  }

  @override
  Future<List<PlaceReviewModel>> getCommunityReviews(String placeId) async {
    try {
      final snapshot = await _firestore
          .collection('places')
          .doc(placeId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PlaceReviewModel.fromCommunityJson(doc.data()))
          .where((review) => review.text.trim().isNotEmpty)
          .toList();
    } on FirebaseException {
      throw ServerException(message: 'Failed to load Atlas reviews.');
    } catch (e) {
      throw ServerException(message: 'Failed to load Atlas reviews.');
    }
  }

  Future<List<String>> _resolvePhotoSources(Map<String, dynamic> json) async {
    final photos = (json['photos'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();

    if (photos.isEmpty) return const [];

    final resolvedSources = <String>[];

    for (final photo in photos.take(6)) {
      final photoName = photo['name'] as String?;
      if (photoName == null || photoName.isEmpty) continue;

      try {
        final response = await _dio.get(
          'https://places.googleapis.com/v1/$photoName/media',
          queryParameters: {
            'maxWidthPx': 1600,
            'skipHttpRedirect': 'true',
            'key': _apiKey,
          },
        );

        final data = response.data as Map<String, dynamic>?;
        final photoUri = data?['photoUri'] as String?;
        if (photoUri != null && photoUri.isNotEmpty) {
          resolvedSources.add(photoUri);
          continue;
        }
      } catch (_) {
        // Fall back to the resource name when the media request cannot be resolved.
      }

      resolvedSources.add(photoName);
    }

    final seen = <String>{};
    return resolvedSources.where(seen.add).toList();
  }
}
