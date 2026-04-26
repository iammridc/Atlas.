import 'package:atlas/features/profile/domain/entities/planned_trip_entity.dart';
import 'package:atlas/features/travel_planner/domain/entities/travel_location_entity.dart';
import 'package:atlas/features/travel_planner/domain/entities/travel_route_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlannedTripModel extends PlannedTripEntity {
  const PlannedTripModel({
    required super.id,
    required super.title,
    required super.routeSummary,
    required super.note,
    required super.updatedAt,
    super.origin,
    super.destination,
    super.route,
    super.selectedPointsOfInterest,
    super.selectedHotels,
  });

  factory PlannedTripModel.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final json = doc.data();
    return PlannedTripModel(
      id: doc.id,
      title: (json['title'] as String?)?.trim() ?? '',
      routeSummary: (json['routeSummary'] as String?)?.trim() ?? '',
      note: (json['note'] as String?)?.trim() ?? '',
      updatedAt: _parseDate(json['updatedAt']),
      origin: _locationFromJson(json['origin']),
      destination: _locationFromJson(json['destination']),
      route: _routeFromJson(json['route']),
      selectedPointsOfInterest: _stopsFromJson(
        json['selectedPointsOfInterest'],
      ),
      selectedHotels: _stopsFromJson(json['selectedHotels']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title.trim(),
      'routeSummary': routeSummary.trim(),
      'note': note.trim(),
      'updatedAt': updatedAt,
      if (origin != null) 'origin': _locationToJson(origin!),
      if (destination != null) 'destination': _locationToJson(destination!),
      if (route != null) 'route': _routeToJson(route!),
      'selectedPointsOfInterest': selectedPointsOfInterest
          .map(_stopToJson)
          .toList(),
      'selectedHotels': selectedHotels.map(_stopToJson).toList(),
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static DateTime? _parseOptionalDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static TravelLocationEntity? _locationFromJson(dynamic value) {
    final json = _asStringMap(value);
    if (json == null) return null;

    return TravelLocationEntity(
      id: _stringValue(json['id']),
      name: _stringValue(json['name']),
      address: _stringValue(json['address']),
      city: _stringValue(json['city']),
      country: _stringValue(json['country']),
      latitude: _doubleValue(json['latitude']),
      longitude: _doubleValue(json['longitude']),
      photoReference: _nullableStringValue(json['photoReference']),
    );
  }

  static Map<String, dynamic> _locationToJson(TravelLocationEntity location) {
    return {
      'id': location.id,
      'name': location.name,
      'address': location.address,
      'city': location.city,
      'country': location.country,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'photoReference': location.photoReference,
    };
  }

  static TravelRouteEntity? _routeFromJson(dynamic value) {
    final json = _asStringMap(value);
    if (json == null) return null;

    return TravelRouteEntity(
      id: _stringValue(json['id']),
      transportType: _enumValue(
        TravelTransportType.values,
        _stringValue(json['transportType']),
        TravelTransportType.best,
      ),
      title: _stringValue(json['title']),
      summary: _stringValue(json['summary']),
      duration: Duration(seconds: _intValue(json['durationSeconds'])),
      distanceMeters: _intValue(json['distanceMeters']),
      priceLabel: _nullableStringValue(json['priceLabel']),
      transferCount: _intValue(json['transferCount']),
      isMocked: json['isMocked'] == true,
      isEstimated: json['isEstimated'] == true,
      bookingUrl: _nullableStringValue(json['bookingUrl']),
      legs: _routeLegsFromJson(json['legs']),
    );
  }

  static Map<String, dynamic> _routeToJson(TravelRouteEntity route) {
    return {
      'id': route.id,
      'transportType': route.transportType.name,
      'title': route.title,
      'summary': route.summary,
      'durationSeconds': route.duration.inSeconds,
      'distanceMeters': route.distanceMeters,
      'priceLabel': route.priceLabel,
      'transferCount': route.transferCount,
      'isMocked': route.isMocked,
      'isEstimated': route.isEstimated,
      'bookingUrl': route.bookingUrl,
      'legs': route.legs.map(_routeLegToJson).toList(),
    };
  }

  static List<TravelRouteLegEntity> _routeLegsFromJson(dynamic value) {
    if (value is! List) return const [];

    return value
        .map(_asStringMap)
        .whereType<Map<String, dynamic>>()
        .map(
          (json) => TravelRouteLegEntity(
            type: _enumValue(
              TravelLegType.values,
              _stringValue(json['type']),
              TravelLegType.transfer,
            ),
            title: _stringValue(json['title']),
            fromName: _stringValue(json['fromName']),
            toName: _stringValue(json['toName']),
            operatorName: _nullableStringValue(json['operatorName']),
            lineName: _nullableStringValue(json['lineName']),
            departureTime: _parseOptionalDate(json['departureTime']),
            arrivalTime: _parseOptionalDate(json['arrivalTime']),
            duration: Duration(seconds: _intValue(json['durationSeconds'])),
            distanceMeters: _intValue(json['distanceMeters']),
            instructions: _stringValue(json['instructions']),
          ),
        )
        .toList();
  }

  static Map<String, dynamic> _routeLegToJson(TravelRouteLegEntity leg) {
    return {
      'type': leg.type.name,
      'title': leg.title,
      'fromName': leg.fromName,
      'toName': leg.toName,
      'operatorName': leg.operatorName,
      'lineName': leg.lineName,
      'departureTime': leg.departureTime,
      'arrivalTime': leg.arrivalTime,
      'durationSeconds': leg.duration.inSeconds,
      'distanceMeters': leg.distanceMeters,
      'instructions': leg.instructions,
    };
  }

  static List<TravelStopEntity> _stopsFromJson(dynamic value) {
    if (value is! List) return const [];

    return value
        .map(_asStringMap)
        .whereType<Map<String, dynamic>>()
        .map(
          (json) => TravelStopEntity(
            id: _stringValue(json['id']),
            name: _stringValue(json['name']),
            address: _stringValue(json['address']),
            latitude: _doubleValue(json['latitude']),
            longitude: _doubleValue(json['longitude']),
            rating: _nullableDoubleValue(json['rating']),
            userRatingCount: _intValue(json['userRatingCount']),
            photoReference: _nullableStringValue(json['photoReference']),
            category: _stringValue(json['category']),
          ),
        )
        .toList();
  }

  static Map<String, dynamic> _stopToJson(TravelStopEntity stop) {
    return {
      'id': stop.id,
      'name': stop.name,
      'address': stop.address,
      'latitude': stop.latitude,
      'longitude': stop.longitude,
      'rating': stop.rating,
      'userRatingCount': stop.userRatingCount,
      'photoReference': stop.photoReference,
      'category': stop.category,
    };
  }

  static T _enumValue<T extends Enum>(List<T> values, String name, T fallback) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }

  static Map<String, dynamic>? _asStringMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  static String _stringValue(dynamic value) => value?.toString().trim() ?? '';

  static String? _nullableStringValue(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static int _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _doubleValue(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _nullableDoubleValue(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
