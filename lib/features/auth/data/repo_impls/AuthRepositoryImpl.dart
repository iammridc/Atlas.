import 'package:dartz/dartz.dart';
import 'package:atlas/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:atlas/features/auth/domain/entities/user_entity.dart';
import 'package:atlas/features/auth/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<String, UserEntity>> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final user = await _datasource.signUp(
        email: email,
        password: password,
        username: username,
      );
      return Right(user);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<String, void>> signOut() async {
    try {
      await _datasource.signOut();
      return const Right(null);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<String, UserEntity?>> getCurrentUser() async {
    try {
      final user = await _datasource.getCurrentUser();
      return Right(user);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  String _handleError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Wrong password.';
        case 'email-already-in-use':
          return 'Email is already in use.';
        case 'invalid-email':
          return 'Invalid email address.';
        case 'weak-password':
          return 'Password is too weak.';
        case 'network-request-failed':
          return 'No internet connection.';
        default:
          return e.message ?? 'An error occurred.';
      }
    }
    return 'An unexpected error occurred.';
  }
}
