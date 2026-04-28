import 'dart:math';

import 'package:atlas/core/errors/app_exception.dart';
import 'package:atlas/core/utils/unit_conversions.dart';
import 'package:atlas/features/travel_planner/domain/entities/travel_location_entity.dart';
import 'package:atlas/features/travel_planner/domain/entities/travel_route_entity.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class TravelPlannerRemoteDatasource {
  Future<List<TravelRouteEntity>> getGoogleRoutes({
    required TravelLocationEntity origin,
    required TravelLocationEntity destination,
  });

  Future<List<TravelRouteEntity>> getFlightRoutes({
    required TravelLocationEntity origin,
    required TravelLocationEntity destination,
  });

  Future<List<TravelStopEntity>> getNearbyPointsOfInterest(
    TravelLocationEntity location,
  );

  Future<List<TravelStopEntity>> getNearbyHotels(TravelLocationEntity location);

  Future<List<TravelLocationEntity>> searchLocations(String query);

  Future<TravelLocationEntity?> reverseGeocodeLocation({
    required double latitude,
    required double longitude,
  });
}

class TravelPlannerRemoteDatasourceImpl
    implements TravelPlannerRemoteDatasource {
  final Dio _dio;

  static const _routesUrl =
      'https://routes.googleapis.com/directions/v2:computeRoutes';
  static const _nearbyUrl =
      'https://places.googleapis.com/v1/places:searchNearby';
  static const _textSearchUrl =
      'https://places.googleapis.com/v1/places:searchText';
  static const _geocodeUrl =
      'https://maps.googleapis.com/maps/api/geocode/json';
  static const _routesFieldMask =
      'routes.duration,'
      'routes.distanceMeters,'
      'routes.description,'
      'routes.localizedValues,'
      'routes.travelAdvisory.transitFare,'
      'routes.legs.steps.distanceMeters,'
      'routes.legs.steps.staticDuration,'
      'routes.legs.steps.travelMode,'
      'routes.legs.steps.localizedValues,'
      'routes.legs.steps.navigationInstruction,'
      'routes.legs.steps.transitDetails';

  static const _nearbyFieldMask =
      'places.id,'
      'places.displayName,'
      'places.formattedAddress,'
      'places.location,'
      'places.rating,'
      'places.userRatingCount,'
      'places.photos,'
      'places.primaryTypeDisplayName,'
      'places.types';

  TravelPlannerRemoteDatasourceImpl({required Dio dio}) : _dio = dio;

  String get _apiKey => dotenv.env['GOOGLE_API_KEY'] ?? '';

  @override
  Future<List<TravelRouteEntity>> getGoogleRoutes({
    required TravelLocationEntity origin,
    required TravelLocationEntity destination,
  }) async {
    final currency = await _preferredCurrency();
    final routeFutures = [
      _fetchRoutesForMode(
        origin: origin,
        destination: destination,
        transportType: TravelTransportType.car,
        travelMode: 'DRIVE',
        currency: currency,
      ),
      _fetchRoutesForMode(
        origin: origin,
        destination: destination,
        transportType: TravelTransportType.bus,
        travelMode: 'TRANSIT',
        allowedTransitModes: const ['BUS'],
        currency: currency,
      ),
      _fetchRoutesForMode(
        origin: origin,
        destination: destination,
        transportType: TravelTransportType.train,
        travelMode: 'TRANSIT',
        allowedTransitModes: const ['TRAIN', 'RAIL'],
        currency: currency,
      ),
    ];

    final settledRoutes = await Future.wait(
      routeFutures.map((future) async {
        try {
          return await future;
        } catch (_) {
          return const <TravelRouteEntity>[];
        }
      }),
    );

    final routes = settledRoutes.expand((route) => route).toList()
      ..sort((a, b) => a.duration.compareTo(b.duration));

    if (routes.isEmpty) {
      throw const ServerException(
        message: 'Google could not build routes for these locations.',
      );
    }

    return routes;
  }

  Future<List<TravelRouteEntity>> _fetchRoutesForMode({
    required TravelLocationEntity origin,
    required TravelLocationEntity destination,
    required TravelTransportType transportType,
    required String travelMode,
    required String currency,
    List<String>? allowedTransitModes,
  }) async {
    final response = await _dio.post(
      _routesUrl,
      data: {
        'origin': _routeWaypoint(origin),
        'destination': _routeWaypoint(destination),
        'travelMode': travelMode,
        if (travelMode == 'DRIVE') 'computeAlternativeRoutes': true,
        if (travelMode == 'TRANSIT')
          'departureTime': DateTime.now()
              .add(const Duration(minutes: 5))
              .toUtc()
              .toIso8601String(),
        'languageCode': 'en',
        'units': 'METRIC',
        if (travelMode == 'TRANSIT')
          'transitPreferences': {
            'routingPreference': 'FEWER_TRANSFERS',
            ...?allowedTransitModes == null
                ? null
                : {'allowedTravelModes': allowedTransitModes},
          },
      },
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask': _routesFieldMask,
        },
      ),
    );

    final routes = response.data['routes'] as List? ?? const [];
    return routes
        .map(
          (route) => _parseRoute(
            route as Map<String, dynamic>,
            origin: origin,
            destination: destination,
            transportType: transportType,
            currency: currency,
          ),
        )
        .where((route) => route.duration > Duration.zero)
        .take(2)
        .toList();
  }

  Map<String, dynamic> _routeWaypoint(TravelLocationEntity location) {
    return {
      'location': {
        'latLng': {
          'latitude': location.latitude,
          'longitude': location.longitude,
        },
      },
    };
  }

  TravelRouteEntity _parseRoute(
    Map<String, dynamic> json, {
    required TravelLocationEntity origin,
    required TravelLocationEntity destination,
    required TravelTransportType transportType,
    required String currency,
  }) {
    final duration = _parseGoogleDuration(json['duration'] as String?);
    final legsJson = json['legs'] as List? ?? const [];
    final stepsJson = legsJson
        .expand(
          (leg) => ((leg as Map<String, dynamic>)['steps'] as List?) ?? [],
        )
        .whereType<Map<String, dynamic>>()
        .toList();
    final parsedLegs = stepsJson
        .map(
          (step) => _parseStep(
            step,
            fallbackOrigin: origin.name,
            fallbackDestination: destination.name,
          ),
        )
        .toList();
    final primaryLegs = transportType == TravelTransportType.car
        ? _mergeCarLegs(
            parsedLegs,
            origin: origin,
            destination: destination,
            duration: duration,
            distanceMeters: _toInt(json['distanceMeters']),
          )
        : parsedLegs.where(_isPrimaryTransportLeg).toList();
    final legs = primaryLegs.isEmpty ? parsedLegs : primaryLegs;
    final transitLegs = legs
        .where(
          (leg) =>
              leg.type == TravelLegType.bus ||
              leg.type == TravelLegType.train ||
              leg.type == TravelLegType.subway ||
              leg.type == TravelLegType.tram,
        )
        .toList();
    final distanceMeters = _toInt(json['distanceMeters']);
    final priceLabel =
        _parseMoneyLabel(json['travelAdvisory'], currency) ??
        _estimatedTransitPriceLabel(
          transportType: transportType,
          distanceMeters: distanceMeters,
          origin: origin,
          destination: destination,
          currency: currency,
        );
    final routeTitle = _routeTitle(transportType, origin, destination, legs);

    return TravelRouteEntity(
      id: '${transportType.name}-${duration.inSeconds}-${json.hashCode}',
      transportType: transportType,
      title: routeTitle,
      summary: _routeSummary(transportType, transitLegs),
      duration: duration,
      distanceMeters: distanceMeters,
      priceLabel: priceLabel,
      transferCount: max(0, transitLegs.length - 1),
      legs: legs.isEmpty
          ? [
              TravelRouteLegEntity(
                type: _legTypeForTransport(transportType),
                title: routeTitle,
                fromName: origin.name,
                toName: destination.name,
                duration: duration,
                distanceMeters: distanceMeters,
              ),
            ]
          : legs,
    );
  }

  List<TravelRouteLegEntity> _mergeCarLegs(
    List<TravelRouteLegEntity> legs, {
    required TravelLocationEntity origin,
    required TravelLocationEntity destination,
    required Duration duration,
    required int distanceMeters,
  }) {
    final carLegs = legs.where((leg) => leg.type == TravelLegType.car).toList();
    if (carLegs.isEmpty) return const [];

    final instructions = carLegs
        .map((leg) => leg.instructions.trim())
        .where((instruction) => instruction.isNotEmpty)
        .toList();

    return [
      TravelRouteLegEntity(
        type: TravelLegType.car,
        title: 'Drive',
        fromName: origin.name,
        toName: destination.name,
        duration: duration,
        distanceMeters: distanceMeters,
        instructions: instructions.join('\n'),
      ),
    ];
  }

  TravelRouteLegEntity _parseStep(
    Map<String, dynamic> json, {
    required String fallbackOrigin,
    required String fallbackDestination,
  }) {
    final travelMode = json['travelMode'] as String? ?? '';
    final transitDetails = json['transitDetails'] as Map<String, dynamic>?;
    final localizedValues = json['localizedValues'] as Map<String, dynamic>?;
    final navigationInstruction =
        json['navigationInstruction'] as Map<String, dynamic>?;
    final distanceText =
        (localizedValues?['distance'] as Map<String, dynamic>?)?['text']
            as String?;

    if (transitDetails != null) {
      final line = transitDetails['transitLine'] as Map<String, dynamic>? ?? {};
      final vehicle = line['vehicle'] as Map<String, dynamic>? ?? {};
      final stopDetails =
          transitDetails['stopDetails'] as Map<String, dynamic>? ?? {};
      final departureStop =
          stopDetails['departureStop'] as Map<String, dynamic>? ?? {};
      final arrivalStop =
          stopDetails['arrivalStop'] as Map<String, dynamic>? ?? {};
      final agencies = line['agencies'] as List? ?? const [];
      final firstAgency = agencies.isNotEmpty
          ? agencies.first as Map<String, dynamic>
          : const <String, dynamic>{};
      final lineName = _firstNonEmpty([
        line['nameShort'] as String?,
        line['name'] as String?,
      ]);
      final vehicleName = _firstNonEmpty([
        (vehicle['name'] as Map<String, dynamic>?)?['text'] as String?,
        vehicle['type'] as String?,
      ]);
      final titleParts = [
        if (vehicleName != null) _formatGoogleEnum(vehicleName),
        ?lineName,
      ];

      return TravelRouteLegEntity(
        type: _legTypeForTransitVehicle(vehicle['type'] as String?),
        title: titleParts.isEmpty ? 'Public transport' : titleParts.join(' '),
        fromName: (departureStop['name'] as String?)?.trim().isNotEmpty == true
            ? departureStop['name'] as String
            : fallbackOrigin,
        toName: (arrivalStop['name'] as String?)?.trim().isNotEmpty == true
            ? arrivalStop['name'] as String
            : fallbackDestination,
        operatorName: firstAgency['name'] as String?,
        lineName: lineName,
        departureTime: _parseDateTime(stopDetails['departureTime'] as String?),
        arrivalTime: _parseDateTime(stopDetails['arrivalTime'] as String?),
        duration: _parseGoogleDuration(json['staticDuration'] as String?),
        distanceMeters: _toInt(json['distanceMeters']),
        instructions: transitDetails['headsign'] as String? ?? '',
      );
    }

    final legType = switch (travelMode) {
      'WALK' => TravelLegType.walking,
      'BICYCLE' => TravelLegType.bicycle,
      'DRIVE' => TravelLegType.car,
      _ => TravelLegType.transfer,
    };

    return TravelRouteLegEntity(
      type: legType,
      title: _titleForLegType(legType),
      fromName: fallbackOrigin,
      toName: fallbackDestination,
      duration: _parseGoogleDuration(json['staticDuration'] as String?),
      distanceMeters: _toInt(json['distanceMeters']),
      instructions:
          _firstNonEmpty([
            navigationInstruction?['instructions'] as String?,
            distanceText,
          ]) ??
          '',
    );
  }

  bool _isPrimaryTransportLeg(TravelRouteLegEntity leg) {
    return switch (leg.type) {
      TravelLegType.car ||
      TravelLegType.bus ||
      TravelLegType.train ||
      TravelLegType.subway ||
      TravelLegType.tram ||
      TravelLegType.flight => true,
      TravelLegType.walking ||
      TravelLegType.bicycle ||
      TravelLegType.transfer => false,
    };
  }

  @override
  Future<List<TravelRouteEntity>> getFlightRoutes({
    required TravelLocationEntity origin,
    required TravelLocationEntity destination,
  }) async {
    final currency = await _preferredCurrency();
    return _getGeneratedFlightRoutes(
      origin: origin,
      destination: destination,
      currency: currency,
    );
  }

  List<TravelRouteEntity> _getGeneratedFlightRoutes({
    required TravelLocationEntity origin,
    required TravelLocationEntity destination,
    required String currency,
  }) {
    final airportOrigin = _airportLabel(origin);
    final airportDestination = _airportLabel(destination);
    final airDistanceKm = max(
      120,
      (_haversineDistanceKm(
        origin.latitude,
        origin.longitude,
        destination.latitude,
        destination.longitude,
      )).round(),
    );
    final flightMinutes = max(55, (airDistanceKm / 760 * 60).round());
    final totalDuration = Duration(minutes: flightMinutes + 105);

    return [
      TravelRouteEntity(
        id: 'flight-direct-${origin.id}-${destination.id}',
        transportType: TravelTransportType.flight,
        title: '$airportOrigin to $airportDestination',
        summary: 'Direct flight',
        duration: totalDuration,
        distanceMeters: airDistanceKm * 1000,
        priceLabel: _flightPrice(
          airDistanceKm,
          direct: true,
          currency: currency,
        ),
        transferCount: 0,
        isMocked: true,
        bookingUrl: _googleFlightsUrl(origin, destination),
        legs: [
          TravelRouteLegEntity(
            type: TravelLegType.flight,
            title: 'Direct flight',
            fromName: airportOrigin,
            toName: airportDestination,
            operatorName: 'Atlas Air',
            lineName: 'AT${100 + airDistanceKm % 800}',
            duration: Duration(minutes: flightMinutes),
            distanceMeters: airDistanceKm * 1000,
            instructions:
                'Check current schedules and fare rules before booking.',
          ),
        ],
      ),
      TravelRouteEntity(
        id: 'flight-transfer-${origin.id}-${destination.id}',
        transportType: TravelTransportType.flight,
        title: '$airportOrigin to $airportDestination',
        summary: '1 transfer flight',
        duration: totalDuration + const Duration(minutes: 95),
        distanceMeters: (airDistanceKm * 1.12).round() * 1000,
        priceLabel: _flightPrice(
          airDistanceKm,
          direct: false,
          currency: currency,
        ),
        transferCount: 1,
        isMocked: true,
        bookingUrl: _googleFlightsUrl(origin, destination),
        legs: [
          TravelRouteLegEntity(
            type: TravelLegType.flight,
            title: 'Flight with transfer',
            fromName: airportOrigin,
            toName: airportDestination,
            operatorName: 'SkyLink Connect',
            lineName: 'AT${300 + airDistanceKm % 500}',
            duration: Duration(minutes: flightMinutes + 95),
            distanceMeters: (airDistanceKm * 1.12).round() * 1000,
            instructions:
                'Connection time is included in the total journey estimate.',
          ),
        ],
      ),
    ];
  }

  @override
  Future<List<TravelStopEntity>> getNearbyPointsOfInterest(
    TravelLocationEntity location,
  ) {
    return _nearbySearch(
      location,
      includedTypes: const [
        'tourist_attraction',
        'museum',
        'park',
        'art_gallery',
      ],
      radius: 5000,
    );
  }

  @override
  Future<List<TravelStopEntity>> getNearbyHotels(
    TravelLocationEntity location,
  ) {
    return _nearbySearch(
      location,
      includedTypes: const ['hotel'],
      radius: 8000,
    );
  }

  Future<List<TravelStopEntity>> _nearbySearch(
    TravelLocationEntity location, {
    required List<String> includedTypes,
    required double radius,
  }) async {
    try {
      final response = await _dio.post(
        _nearbyUrl,
        data: {
          'includedTypes': includedTypes,
          'maxResultCount': 10,
          'rankPreference': 'POPULARITY',
          'locationRestriction': {
            'circle': {
              'center': {
                'latitude': location.latitude,
                'longitude': location.longitude,
              },
              'radius': radius,
            },
          },
          'languageCode': 'en',
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': _apiKey,
            'X-Goog-FieldMask': _nearbyFieldMask,
          },
        ),
      );

      final places = response.data['places'] as List? ?? const [];
      return places
          .map((place) => _parseStop(place as Map<String, dynamic>))
          .where((place) => place.name.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        message:
            e.response?.data?['error']?['message'] ??
            'Failed to load nearby places.',
      );
    } catch (_) {
      throw const ServerException(message: 'Failed to load nearby places.');
    }
  }

  @override
  Future<List<TravelLocationEntity>> searchLocations(String query) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) return const [];

    try {
      final response = await _dio.post(
        _textSearchUrl,
        data: {
          'textQuery': normalizedQuery,
          'pageSize': 8,
          'languageCode': 'en',
          'rankPreference': 'RELEVANCE',
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': _apiKey,
            'X-Goog-FieldMask':
                'places.id,places.displayName,places.formattedAddress,'
                'places.location,places.addressComponents,places.photos',
          },
        ),
      );

      final places = response.data['places'] as List? ?? const [];
      return places
          .map((place) => _parseLocation(place as Map<String, dynamic>))
          .where((place) => place.name.isNotEmpty && place.hasCoordinates)
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        message:
            e.response?.data?['error']?['message'] ??
            'Failed to search locations.',
      );
    } catch (_) {
      throw const ServerException(message: 'Failed to search locations.');
    }
  }

  @override
  Future<TravelLocationEntity?> reverseGeocodeLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.get(
        _geocodeUrl,
        queryParameters: {
          'latlng': '$latitude,$longitude',
          'key': _apiKey,
          'language': 'en',
          'result_type':
              'locality|postal_town|administrative_area_level_1|street_address|route',
        },
      );

      final results = response.data['results'] as List? ?? const [];
      if (results.isEmpty) {
        return _currentLocationFallback(latitude, longitude);
      }

      final bestResult = results.first as Map<String, dynamic>;
      final components = bestResult['address_components'] as List? ?? const [];
      final cityCountry = _extractLegacyCityCountry(components);
      final formattedAddress = bestResult['formatted_address'] as String? ?? '';
      final fallbackName = _shortAddressName(formattedAddress);
      final resolvedName = cityCountry.city.isNotEmpty
          ? cityCountry.city
          : fallbackName;

      return TravelLocationEntity(
        id: bestResult['place_id'] as String? ?? 'current-location',
        name: resolvedName.isNotEmpty ? resolvedName : 'Current location',
        address: formattedAddress.isNotEmpty
            ? formattedAddress
            : (resolvedName.isNotEmpty ? resolvedName : 'Current location'),
        city: cityCountry.city,
        country: cityCountry.country,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (_) {
      return _currentLocationFallback(latitude, longitude);
    }
  }

  TravelLocationEntity _parseLocation(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>? ?? {};
    final photos = json['photos'] as List? ?? const [];
    final components = json['addressComponents'] as List? ?? const [];
    final cityCountry = _extractCityCountry(components);

    return TravelLocationEntity(
      id: json['id'] as String? ?? '',
      name:
          (json['displayName'] as Map<String, dynamic>?)?['text'] as String? ??
          '',
      address: json['formattedAddress'] as String? ?? '',
      city: cityCountry.city,
      country: cityCountry.country,
      latitude: _toDouble(location['latitude']),
      longitude: _toDouble(location['longitude']),
      photoReference: photos.isNotEmpty
          ? (photos.first as Map<String, dynamic>)['name'] as String?
          : null,
    );
  }

  TravelStopEntity _parseStop(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>? ?? {};
    final photos = json['photos'] as List? ?? const [];
    final primaryTypeDisplayName =
        json['primaryTypeDisplayName'] as Map<String, dynamic>?;
    final types = List<String>.from(json['types'] ?? const []);

    return TravelStopEntity(
      id: json['id'] as String? ?? '',
      name:
          (json['displayName'] as Map<String, dynamic>?)?['text'] as String? ??
          '',
      address: json['formattedAddress'] as String? ?? '',
      latitude: _toDouble(location['latitude']),
      longitude: _toDouble(location['longitude']),
      rating: _toNullableDouble(json['rating']),
      userRatingCount: _toInt(json['userRatingCount']),
      photoReference: photos.isNotEmpty
          ? (photos.first as Map<String, dynamic>)['name'] as String?
          : null,
      category:
          primaryTypeDisplayName?['text'] as String? ??
          (types.isNotEmpty ? _formatGoogleEnum(types.first) : 'Place'),
    );
  }

  ({String city, String country}) _extractCityCountry(
    List<dynamic> components,
  ) {
    var city = '';
    var country = '';

    for (final component in components.whereType<Map<String, dynamic>>()) {
      final types = List<String>.from(component['types'] ?? const []);
      final value = component['longText'] as String? ?? '';
      if (value.isEmpty) continue;

      if (city.isEmpty &&
          (types.contains('locality') ||
              types.contains('administrative_area_level_1'))) {
        city = value;
      }
      if (types.contains('country')) {
        country = value;
      }
    }

    return (city: city, country: country);
  }

  ({String city, String country}) _extractLegacyCityCountry(
    List<dynamic> components,
  ) {
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

    return (city: city, country: country);
  }

  TravelLocationEntity _currentLocationFallback(
    double latitude,
    double longitude,
  ) {
    return TravelLocationEntity(
      id: 'current-location',
      name: 'Current location',
      address: 'Current location',
      city: '',
      country: '',
      latitude: latitude,
      longitude: longitude,
    );
  }

  String _shortAddressName(String address) {
    return address
        .split(',')
        .map((part) => part.trim())
        .firstWhere((part) => part.isNotEmpty, orElse: () => '');
  }

  String _routeTitle(
    TravelTransportType type,
    TravelLocationEntity origin,
    TravelLocationEntity destination,
    List<TravelRouteLegEntity> legs,
  ) {
    if (type == TravelTransportType.bus || type == TravelTransportType.train) {
      final publicLegs = legs
          .where((leg) => leg.lineName != null && leg.lineName!.isNotEmpty)
          .map((leg) => leg.lineName!)
          .take(3)
          .toList();
      if (publicLegs.isNotEmpty) return publicLegs.join(' > ');
    }

    return switch (type) {
      TravelTransportType.car => 'Drive to ${destination.name}',
      TravelTransportType.bus => 'Bus to ${destination.name}',
      TravelTransportType.train => 'Train to ${destination.name}',
      TravelTransportType.flight => 'Fly to ${destination.name}',
      TravelTransportType.best => '${origin.name} to ${destination.name}',
    };
  }

  String _routeSummary(
    TravelTransportType type,
    List<TravelRouteLegEntity> transitLegs,
  ) {
    if ((type == TravelTransportType.bus ||
            type == TravelTransportType.train) &&
        transitLegs.isNotEmpty) {
      final labels = transitLegs
          .map((leg) => leg.lineName ?? leg.operatorName ?? leg.title)
          .where((label) => label.trim().isNotEmpty)
          .take(4)
          .join(' > ');
      return labels.isEmpty ? 'Public transport' : labels;
    }

    return switch (type) {
      TravelTransportType.car => 'Driving route',
      TravelTransportType.bus => 'Bus route',
      TravelTransportType.train => 'Train route',
      TravelTransportType.flight => 'Flight route',
      TravelTransportType.best => 'Recommended route',
    };
  }

  TravelLegType _legTypeForTransport(TravelTransportType type) {
    return switch (type) {
      TravelTransportType.car => TravelLegType.car,
      TravelTransportType.flight => TravelLegType.flight,
      TravelTransportType.bus ||
      TravelTransportType.train ||
      TravelTransportType.best => TravelLegType.transfer,
    };
  }

  TravelLegType _legTypeForTransitVehicle(String? vehicleType) {
    return switch (vehicleType) {
      'BUS' ||
      'INTERCITY_BUS' ||
      'TROLLEYBUS' ||
      'SHARE_TAXI' => TravelLegType.bus,
      'RAIL' ||
      'HEAVY_RAIL' ||
      'COMMUTER_TRAIN' ||
      'HIGH_SPEED_TRAIN' => TravelLegType.train,
      'SUBWAY' || 'METRO_RAIL' => TravelLegType.subway,
      'TRAM' || 'LIGHT_RAIL' => TravelLegType.tram,
      _ => TravelLegType.train,
    };
  }

  String _titleForLegType(TravelLegType type) {
    return switch (type) {
      TravelLegType.car => 'Drive',
      TravelLegType.walking => 'Walk',
      TravelLegType.bicycle => 'Bike',
      TravelLegType.flight => 'Flight',
      TravelLegType.bus => 'Bus',
      TravelLegType.train => 'Train',
      TravelLegType.subway => 'Subway',
      TravelLegType.tram => 'Tram',
      TravelLegType.transfer => 'Transfer',
    };
  }

  Duration _parseGoogleDuration(String? rawValue) {
    if (rawValue == null || rawValue.isEmpty) return Duration.zero;
    final seconds = int.tryParse(rawValue.replaceAll('s', '')) ?? 0;
    return Duration(seconds: seconds);
  }

  DateTime? _parseDateTime(String? rawValue) {
    if (rawValue == null || rawValue.isEmpty) return null;
    return DateTime.tryParse(rawValue)?.toLocal();
  }

  String? _parseMoneyLabel(dynamic advisory, String preferredCurrency) {
    final json = advisory as Map<String, dynamic>?;
    final fare = json?['transitFare'] as Map<String, dynamic>?;
    if (fare == null) return null;

    final sourceCurrency = fare['currencyCode'] as String? ?? 'USD';
    final units = fare['units']?.toString() ?? '';
    final nanos = _toInt(fare['nanos']);
    if (units.isEmpty && nanos == 0) return null;
    final amount = (double.tryParse(units) ?? 0) + nanos / 1000000000;
    return _formatRouteFare(
      amount: amount,
      fromCurrency: sourceCurrency,
      toCurrency: preferredCurrency,
    );
  }

  String? _estimatedTransitPriceLabel({
    required TravelTransportType transportType,
    required int distanceMeters,
    required TravelLocationEntity origin,
    required TravelLocationEntity destination,
    required String currency,
  }) {
    if (transportType != TravelTransportType.bus &&
        transportType != TravelTransportType.train) {
      return null;
    }

    final routeDistanceKm = distanceMeters > 0
        ? distanceMeters / 1000
        : _haversineDistanceKm(
            origin.latitude,
            origin.longitude,
            destination.latitude,
            destination.longitude,
          );
    final minimumFare = transportType == TravelTransportType.bus ? 2.0 : 4.0;
    final baseFare = transportType == TravelTransportType.bus ? 1.5 : 3.0;
    final distanceRate = transportType == TravelTransportType.bus
        ? 0.055
        : 0.08;
    final estimatedPrice = max(
      minimumFare,
      baseFare + routeDistanceKm * distanceRate,
    );

    return _formatRouteFare(
      amount: estimatedPrice,
      fromCurrency: 'USD',
      toCurrency: currency,
    );
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final normalized = value?.trim();
      if (normalized != null && normalized.isNotEmpty) return normalized;
    }
    return null;
  }

  String _airportLabel(TravelLocationEntity location) {
    final city = location.city.trim().isNotEmpty
        ? location.city
        : location.name.trim().isNotEmpty
        ? location.name
        : 'Local';
    return '$city Airport';
  }

  String _flightPrice(
    int distanceKm, {
    required bool direct,
    required String currency,
  }) {
    final base = direct ? 65 : 48;
    final price = base + (distanceKm * (direct ? 0.09 : 0.07)).round();
    return _formatRouteFare(
      amount: price.toDouble(),
      fromCurrency: 'USD',
      toCurrency: currency,
    );
  }

  String _formatRouteFare({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) {
    final normalizedCurrency = UnitConversions.normalizeCurrency(toCurrency);
    final convertedAmount = UnitConversions.convertCurrency(
      amount: amount,
      fromCurrency: fromCurrency,
      toCurrency: normalizedCurrency,
    );
    final decimals = normalizedCurrency == 'USD' || normalizedCurrency == 'EUR'
        ? 2
        : 0;
    return 'from ${convertedAmount.toStringAsFixed(decimals)} $normalizedCurrency';
  }

  Future<String> _preferredCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final currency = prefs.getString(UnitConversions.currencyKey) ?? 'USD';
    final normalized = UnitConversions.normalizeCurrency(currency);
    if (currency != normalized) {
      await prefs.setString(UnitConversions.currencyKey, normalized);
    }
    return normalized;
  }

  String _googleFlightsUrl(
    TravelLocationEntity origin,
    TravelLocationEntity destination,
  ) {
    final query = Uri.encodeComponent('${origin.name} to ${destination.name}');
    return 'https://www.google.com/travel/flights?q=$query';
  }

  double _haversineDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const radiusKm = 6371;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return radiusKm * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _toRadians(double degrees) => degrees * pi / 180;

  String _formatGoogleEnum(String value) {
    return value
        .split('_')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  double? _toNullableDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
