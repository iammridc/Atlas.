import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:atlas/features/auth/domain/usecases/signin_usecase.dart';
import 'package:atlas/features/auth/domain/usecases/signup_usecase.dart';
import 'package:atlas/features/auth/domain/usecases/signout_usecase.dart';
import 'package:atlas/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:atlas/core/theme/cubit/theme_cubit.dart';
import 'package:atlas/core/injections/injections.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final SignInUseCase _signInUseCase;
  final SignUpUseCase _signUpUseCase;
  final SignOutUseCase _signOutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;

  AuthCubit({
    required SignInUseCase signInUseCase,
    required SignUpUseCase signUpUseCase,
    required SignOutUseCase signOutUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
  }) : _signInUseCase = signInUseCase,
       _signUpUseCase = signUpUseCase,
       _signOutUseCase = signOutUseCase,
       _getCurrentUserUseCase = getCurrentUserUseCase,
       super(AuthInitial());

  Future<void> checkCurrentUser() async {
    emit(AuthLoading());
    final result = await _getCurrentUserUseCase();
    result.fold((error) => emit(AuthUnauthenticated()), (user) {
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    });
  }

  Future<void> signIn({required String email, required String password}) async {
    emit(AuthLoading());
    final result = await _signInUseCase(email: email, password: password);
    result.fold((error) => emit(AuthError(error)), (user) async {
      // load user theme after login
      await getIt<ThemeCubit>().loadUserTheme(user.id);
      emit(AuthAuthenticated(user));
    });
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    emit(AuthLoading());
    final result = await _signUpUseCase(
      email: email,
      password: password,
      username: username,
    );
    result.fold(
      (error) => emit(AuthError(error)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> signOut() async {
    emit(AuthLoading());
    final result = await _signOutUseCase();
    result.fold((error) => emit(AuthError(error)), (_) {
      // reset theme on logout
      getIt<ThemeCubit>().resetTheme();
      emit(AuthUnauthenticated());
    });
  }
}
