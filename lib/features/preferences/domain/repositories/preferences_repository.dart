import 'package:dartz/dartz.dart';
import 'package:atlas/core/errors/app_exception.dart';
import 'package:atlas/features/preferences/domain/entities/category_entity.dart';

abstract class PreferencesRepository {
  Future<Either<AppException, List<CategoryEntity>>> getCategories();
  Future<Either<AppException, void>> savePreferences(
    String uid,
    List<String> categoryIds,
  );
  Future<Either<AppException, bool>> hasPreferences(String uid);
}
