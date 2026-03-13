import 'package:dartz/dartz.dart';
import 'package:atlas/features/auth/domain/entities/user_entity.dart';
import 'package:atlas/features/auth/domain/repositories/auth_repository.dart';

class SignInUseCase {
  final AuthRepository _repository;

  SignInUseCase(this._repository);

  Future<Either<String, UserEntity>> call({
    required String email,
    required String password,
  }) {
    return _repository.signIn(email: email, password: password);
  }
}
