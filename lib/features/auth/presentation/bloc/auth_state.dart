import 'package:atlas/features/auth/domain/entities/user_entity.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserEntity user;
  AuthAuthenticated(this.user);
}

class AuthNeedsPreferences extends AuthState {
  final UserEntity user;
  AuthNeedsPreferences(this.user);
  List<Object?> get props => [user];
}

class AuthRegistered extends AuthState {}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}
