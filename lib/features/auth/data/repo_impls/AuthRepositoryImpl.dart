import 'package:dartz/dartz.dart';
import 'package:atlas/core/errors/auth_exception.dart';
import 'package:atlas/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:atlas/features/auth/domain/entities/user_entity.dart';
import 'package:atlas/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _datasource;

  AuthRepositoryImpl(this._datasource);

  @override
  Future<Either<String, UserEntity>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _datasource.signIn(email: email, password: password);
      return Right(user);
    } on AuthException catch (e) {
      return Left(e.message);
    } catch (e) {
      return const Left('An unexpected error occurred.');
    }
  }

  @override
  Future<Either<String, UserEntity>> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _datasource.signUp(email: email, password: password);
      return Right(user);
    } on AuthException catch (e) {
      return Left(e.message);
    } catch (e) {
      return const Left('An unexpected error occurred.');
    }
  }

  @override
  Future<Either<String, void>> signOut() async {
    try {
      await _datasource.signOut();
      return const Right(null);
    } on AuthException catch (e) {
      return Left(e.message);
    } catch (e) {
      return const Left('An unexpected error occurred.');
    }
  }

  @override
  Future<Either<String, void>> deleteAccount() async {
    try {
      await _datasource.deleteAccount();
      return const Right(null);
    } on AuthException catch (e) {
      return Left(e.message);
    } catch (e) {
      return const Left('An unexpected error occurred.');
    }
  }

  @override
  Future<Either<String, UserEntity?>> getCurrentUser() async {
    try {
      final user = await _datasource.getCurrentUser();
      return Right(user);
    } on AuthException catch (e) {
      return Left(e.message);
    } catch (e) {
      return const Left('An unexpected error occurred.');
    }
  }
}
