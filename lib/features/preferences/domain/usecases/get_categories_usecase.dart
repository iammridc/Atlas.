import 'package:atlas/core/errors/app_exception.dart';
import 'package:dartz/dartz.dart';
import 'package:atlas/features/preferences/domain/entities/category_entity.dart';
import 'package:atlas/features/preferences/domain/repositories/preferences_repository.dart';

class GetCategoriesUseCase {
  final PreferencesRepository _repository;

  GetCategoriesUseCase(this._repository);

  Future<Either<AppException, List<CategoryEntity>>> call() {
    return _repository.getCategories();
  }
}
