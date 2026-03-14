import 'package:dartz/dartz.dart';
import 'package:atlas/features/auth/domain/entities/user_entity.dart';
import 'package:atlas/features/auth/domain/repositories/auth_repository.dart';

class SignUpUseCase {
  final AuthRepository _repository;

  SignUpUseCase(this._repository);

  Future<Either<String, UserEntity>> call({
    required String email,
    required String password,
  }) {
    return _repository.signUp(email: email, password: password);
  }
}
