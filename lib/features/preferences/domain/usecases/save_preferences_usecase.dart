import 'package:atlas/core/errors/app_exception.dart';
import 'package:dartz/dartz.dart';

import 'package:atlas/features/preferences/domain/repositories/preferences_repository.dart';
import 'package:equatable/equatable.dart';

class SavePreferencesUseCase {
  final PreferencesRepository _repository;

  SavePreferencesUseCase(this._repository);

  Future<Either<AppException, void>> call(SavePreferencesParams params) {
    return _repository.savePreferences(params.uid, params.categoryIds);
  }
}

class SavePreferencesParams extends Equatable {
  final String uid;
  final List<String> categoryIds;

  const SavePreferencesParams({required this.uid, required this.categoryIds});

  @override
  List<Object?> get props => [uid, categoryIds];
}
