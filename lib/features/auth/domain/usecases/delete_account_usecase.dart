import 'package:atlas/features/auth/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';

class DeleteAccountUseCase {
  final AuthRepository _repository;

  DeleteAccountUseCase(this._repository);

  Future<Either<String, void>> call() {
    return _repository.deleteAccount();
  }
}
