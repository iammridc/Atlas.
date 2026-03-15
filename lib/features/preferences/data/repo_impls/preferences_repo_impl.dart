import 'package:atlas/core/errors/app_exception.dart';
import 'package:atlas/features/preferences/data/datasources/preferences_remote_datasource.dart';
import 'package:atlas/features/preferences/domain/entities/category_entity.dart';
import 'package:atlas/features/preferences/domain/repositories/preferences_repository.dart';
import 'package:dartz/dartz.dart';

class PreferencesRepositoryImpl implements PreferencesRepository {
  final PreferencesRemoteDatasource _datasource;

  PreferencesRepositoryImpl(this._datasource);

  @override
  Future<Either<AppException, List<CategoryEntity>>> getCategories() async {
    try {
      final categories = await _datasource.getCategories();
      return Right(categories);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownException(message: e.toString()));
    }
  }

  @override
  Future<Either<AppException, void>> savePreferences(
    String uid,
    List<String> categoryIds,
  ) async {
    try {
      await _datasource.savePreferences(uid, categoryIds);
      return const Right(null);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownException(message: e.toString()));
    }
  }

  @override
  Future<Either<AppException, bool>> hasPreferences(String uid) async {
    try {
      final result = await _datasource.hasPreferences(uid);
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownException(message: e.toString()));
    }
  }
}
