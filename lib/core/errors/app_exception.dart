abstract class AppException implements Exception {
  final String message;
  final String code;

  const AppException({required this.message, required this.code});

  @override
  String toString() => message;
}

class ServerException extends AppException {
  const ServerException({required super.message, super.code = 'server_error'});
}

class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.code = 'network_error',
  });
}

class CacheException extends AppException {
  const CacheException({required super.message, super.code = 'cache_error'});
}

class UnknownException extends AppException {
  const UnknownException({
    required super.message,
    super.code = 'unknown_error',
  });
}
