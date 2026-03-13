import 'package:dartz/dartz.dart';
import 'package:atlas/features/auth/domain/entities/user_entity.dart';
import 'package:atlas/features/auth/domain/repositories/auth_repository.dart';

class GetCurrentUserUseCase {
  final AuthRepository _repository;

  GetCurrentUserUseCase(this._repository);

  Future<Either<String, UserEntity?>> call() {
    return _repository.getCurrentUser();
  }
}
