import 'package:atlas/core/errors/app_exception.dart';

class AuthException extends AppException {
  const AuthException({required super.message, required super.code});
}
