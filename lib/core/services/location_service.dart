import 'package:geolocator/geolocator.dart';

class LocationPoint {
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final DateTime timestamp;
  final bool isMocked;

  const LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.timestamp,
    required this.isMocked,
  });
}

abstract class LocationService {
  Future<LocationPoint?> getCurrentLocation();
}

class GeolocatorLocationService implements LocationService {
  static const _maxAcceptedAccuracyMeters = 1000.0;
  static const _maxAcceptedAge = Duration(minutes: 2);

  @override
  Future<LocationPoint?> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
          timeLimit: Duration(seconds: 12),
        ),
      );

      if (!_isUsablePosition(position)) return null;

      return LocationPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
        timestamp: position.timestamp,
        isMocked: position.isMocked,
      );
    } catch (_) {
      return null;
    }
  }

  bool _isUsablePosition(Position position) {
    final latitude = position.latitude;
    final longitude = position.longitude;
    final isValidCoordinate =
        latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        (latitude != 0 || longitude != 0);

    if (!isValidCoordinate || position.isMocked) return false;
    if (position.accuracy <= 0 ||
        position.accuracy > _maxAcceptedAccuracyMeters) {
      return false;
    }

    final age = DateTime.now().difference(position.timestamp).abs();
    return age <= _maxAcceptedAge;
  }
}
