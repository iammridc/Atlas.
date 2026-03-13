import 'package:dartz/dartz.dart';
import 'package:atlas/features/auth/domain/repositories/auth_repository.dart';

class SignOutUseCase {
  final AuthRepository _repository;

  SignOutUseCase(this._repository);

  Future<Either<String, void>> call() {
    return _repository.signOut();
  }
}
