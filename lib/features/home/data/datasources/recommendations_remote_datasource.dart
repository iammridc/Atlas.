// recommendations_remote_datasource.dart

import 'dart:math';
import 'package:atlas/core/errors/app_exception.dart';
import 'package:atlas/features/home/data/models/recommendation_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract class RecommendationsRemoteDatasource {
  Future<List<RecommendationModel>> getRecommendations(
    List<String> categoryTypes,
  );
}

class RecommendationsRemoteDatasourceImpl
    implements RecommendationsRemoteDatasource {
  final Dio _dio;

  static const _baseUrl = 'https://places.googleapis.com/v1/places:searchText';
  static const _fieldMask =
      'places.id,'
      'places.displayName,'
      'places.addressComponents,'
      'places.photos';

  static const _queryPrefixes = [
    'world famous',
    'most visited',
    'top rated',
    'iconic',
    'must see',
    'best',
    'popular',
    'legendary',
    'breathtaking',
    'hidden gem',
  ];

  RecommendationsRemoteDatasourceImpl({required Dio dio}) : _dio = dio;

  String get _apiKey => dotenv.env['GOOGLE_API_KEY'] ?? '';

  @override
  Future<List<RecommendationModel>> getRecommendations(
    List<String> categoryTypes,
  ) async {
    final futures = categoryTypes.map(_fetchByCategory);
    final results = await Future.wait(futures);

    final seen = <String>{};
    final combined = results
        .expand((places) => places)
        .where((place) => seen.add(place.id))
        .toList();

    combined.shuffle(Random());
    return combined;
  }

  Future<List<RecommendationModel>> _fetchByCategory(
    String categoryType,
  ) async {
    try {
      final prefix = _queryPrefixes[Random().nextInt(_queryPrefixes.length)];

      final response = await _dio.post(
        _baseUrl,
        data: {
          'textQuery': '$prefix ${categoryType.replaceAll('_', ' ')}',
          'pageSize': 10,
          'languageCode': 'en',
          'rankPreference': 'RELEVANCE',
        },
        options: Options(
          headers: {'X-Goog-Api-Key': _apiKey, 'X-Goog-FieldMask': _fieldMask},
        ),
      );

      final places = response.data['places'] as List? ?? [];
      return places.map((p) => RecommendationModel.fromJson(p)).toList();
    } on DioException catch (e) {
      throw ServerException(
        message:
            e.response?.data?['error']?['message'] ??
            'Failed to fetch category: $categoryType',
      );
    }
  }
}
