import 'package:atlas/features/preferences/domain/usecases/has_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:atlas/features/auth/domain/usecases/signin_usecase.dart';
import 'package:atlas/features/auth/domain/usecases/signup_usecase.dart';
import 'package:atlas/features/auth/domain/usecases/signout_usecase.dart';
import 'package:atlas/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:atlas/features/auth/domain/usecases/delete_account_usecase.dart';
import 'package:atlas/core/theme/cubit/theme_cubit.dart';
import 'package:atlas/core/injections/injections.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final SignInUseCase _signInUseCase;
  final SignUpUseCase _signUpUseCase;
  final SignOutUseCase _signOutUseCase;
  final DeleteAccountUseCase _deleteAccountUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final HasPreferencesUseCase _hasPreferencesUseCase;

  AuthCubit({
    required SignInUseCase signInUseCase,
    required SignUpUseCase signUpUseCase,
    required SignOutUseCase signOutUseCase,
    required DeleteAccountUseCase deleteAccountUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required HasPreferencesUseCase hasPreferencesUseCase,
  }) : _signInUseCase = signInUseCase,
       _signUpUseCase = signUpUseCase,
       _signOutUseCase = signOutUseCase,
       _deleteAccountUseCase = deleteAccountUseCase,
       _getCurrentUserUseCase = getCurrentUserUseCase,
       _hasPreferencesUseCase = hasPreferencesUseCase,
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_logged_in_uid', user.id);
      await prefs.setBool('biometrics_enabled_${user.id}', true);
      await getIt<ThemeCubit>().loadUserTheme(user.id);

      final hasPrefsResult = await _hasPreferencesUseCase(user.id);
      final hasPrefs = hasPrefsResult.fold((_) => false, (v) => v);

      emit(AuthAuthenticated(user));
      if (!hasPrefs) emit(AuthNeedsPreferences(user));
    });
  }

  Future<void> signUp({required String email, required String password}) async {
    emit(AuthLoading());
    final result = await _signUpUseCase(email: email, password: password);
    result.fold((error) => emit(AuthError(error)), (user) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_logged_in_uid', user.id);
      await prefs.setBool('biometrics_enabled_${user.id}', true);
      emit(AuthRegistered());
    });
  }

  Future<void> signOut() async {
    emit(AuthLoading());
    final result = await _signOutUseCase();
    result.fold((error) => emit(AuthError(error)), (_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_logged_in_uid');
      getIt<ThemeCubit>().resetTheme();
      emit(AuthUnauthenticated());
    });
  }

  Future<void> deleteAccount() async {
    emit(AuthLoading());
    final result = await _deleteAccountUseCase();
    result.fold((error) => emit(AuthError(error)), (_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_logged_in_uid');
      getIt<ThemeCubit>().resetTheme();
      emit(AuthUnauthenticated());
    });
  }
}
