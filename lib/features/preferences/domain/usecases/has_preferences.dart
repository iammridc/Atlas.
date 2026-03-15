import 'package:atlas/core/errors/app_exception.dart';
import 'package:dartz/dartz.dart';
import 'package:atlas/features/preferences/domain/repositories/preferences_repository.dart';

class HasPreferencesUseCase {
  final PreferencesRepository _repository;

  HasPreferencesUseCase(this._repository);

  Future<Either<AppException, bool>> call(String uid) {
    return _repository.hasPreferences(uid);
  }
}
