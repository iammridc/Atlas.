import 'package:atlas/core/errors/app_exception.dart';
import 'package:atlas/features/home/data/models/recommendation_model.dart';
import 'package:atlas/features/home/domain/entity/home_map_entity.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract class HomeMapRemoteDatasource {
  Future<List<RecommendationModel>> getNearbyPlaces({
    required HomeMapCoordinateEntity center,
    required double radiusMeters,
  });

  Future<RecommendationModel?> findNearestPlace({
    required HomeMapCoordinateEntity center,
    required double radiusMeters,
  });

  Future<HomeMapLocationEntity?> resolveLocation({
    required HomeMapCoordinateEntity center,
  });
}

class HomeMapRemoteDatasourceImpl implements HomeMapRemoteDatasource {
  final Dio _dio;

  static const _nearbyUrl =
      'https://places.googleapis.com/v1/places:searchNearby';
  static const _geocodeUrl =
      'https://maps.googleapis.com/maps/api/geocode/json';
  static const _fieldMask =
      'places.id,'
      'places.displayName,'
      'places.addressComponents,'
      'places.photos,'
      'places.location,'
      'places.primaryTypeDisplayName,'
      'places.types';
  static const _includedTypes = [
    'tourist_attraction',
    'museum',
    'park',
    'art_gallery',
    'restaurant',
    'cafe',
    'shopping_mall',
  ];

  HomeMapRemoteDatasourceImpl({required Dio dio}) : _dio = dio;

  String get _apiKey => dotenv.env['GOOGLE_API_KEY'] ?? '';

  @override
  Future<List<RecommendationModel>> getNearbyPlaces({
    required HomeMapCoordinateEntity center,
    required double radiusMeters,
  }) async {
    return _nearbySearch(
      center: center,
      radiusMeters: radiusMeters,
      maxResultCount: 20,
      rankPreference: 'POPULARITY',
      includedTypes: _includedTypes,
      emptyMessage: 'Failed to load nearby places.',
    );
  }

  @override
  Future<RecommendationModel?> findNearestPlace({
    required HomeMapCoordinateEntity center,
    required double radiusMeters,
  }) async {
    final places = await _nearbySearch(
      center: center,
      radiusMeters: radiusMeters,
      maxResultCount: 8,
      rankPreference: 'DISTANCE',
      emptyMessage: 'Failed to inspect this place.',
    );

    return places.isEmpty ? null : places.first;
  }

  @override
  Future<HomeMapLocationEntity?> resolveLocation({
    required HomeMapCoordinateEntity center,
  }) async {
    try {
      final response = await _dio.get(
        _geocodeUrl,
        queryParameters: {
          'latlng': '${center.latitude},${center.longitude}',
          'key': _apiKey,
          'language': 'en',
          'result_type':
              'locality|postal_town|administrative_area_level_1|street_address|route',
        },
      );

      final results = response.data['results'] as List? ?? const [];
      if (results.isEmpty) return null;

      final bestResult = results.first as Map<String, dynamic>;
      final components = bestResult['address_components'] as List? ?? const [];
      final location = _extractLegacyCityCountry(components);

      return location.hasLocationLabel ? location : null;
    } on DioException catch (e) {
      throw ServerException(
        message:
            e.response?.data?['error_message'] ??
            e.response?.data?['error']?['message'] ??
            'Failed to resolve your current location.',
      );
    } catch (_) {
      throw const ServerException(
        message: 'Failed to resolve your current location.',
      );
    }
  }

  Future<List<RecommendationModel>> _nearbySearch({
    required HomeMapCoordinateEntity center,
    required double radiusMeters,
    required int maxResultCount,
    required String rankPreference,
    List<String>? includedTypes,
    required String emptyMessage,
  }) async {
    final typeFilter = includedTypes == null
        ? const <String, dynamic>{}
        : {'includedTypes': includedTypes};

    try {
      final response = await _dio.post(
        _nearbyUrl,
        data: {
          ...typeFilter,
          'maxResultCount': maxResultCount,
          'rankPreference': rankPreference,
          'locationRestriction': {
            'circle': {
              'center': {
                'latitude': center.latitude,
                'longitude': center.longitude,
              },
              'radius': radiusMeters,
            },
          },
          'languageCode': 'en',
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': _apiKey,
            'X-Goog-FieldMask': _fieldMask,
          },
        ),
      );

      final places = response.data['places'] as List? ?? const [];
      return places
          .map((place) => RecommendationModel.fromJson(place))
          .where((place) => place.name.trim().isNotEmpty)
          .where((place) => place.hasCoordinates)
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['error']?['message'] ?? emptyMessage,
      );
    } catch (_) {
      throw ServerException(message: emptyMessage);
    }
  }

  HomeMapLocationEntity _extractLegacyCityCountry(List<dynamic> components) {
    var city = '';
    var country = '';

    for (final component in components.whereType<Map<String, dynamic>>()) {
      final types = List<String>.from(component['types'] ?? const []);
      final value = component['long_name'] as String? ?? '';
      if (value.isEmpty) continue;

      if (city.isEmpty &&
          (types.contains('locality') ||
              types.contains('postal_town') ||
              types.contains('administrative_area_level_1'))) {
        city = value;
      }
      if (types.contains('country')) {
        country = value;
      }
    }

    return HomeMapLocationEntity(city: city, country: country);
  }
}
