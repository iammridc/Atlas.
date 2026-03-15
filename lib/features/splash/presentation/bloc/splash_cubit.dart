import 'package:atlas/core/injections/injections.dart';
import 'package:atlas/features/preferences/domain/usecases/has_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  final _auth = LocalAuthentication();
  static const _lastUserKey = 'last_logged_in_uid';

  SplashCubit() : super(SplashInitial());

  Future<void> init() async {
    emit(SplashLogoVisible());
    await Future.delayed(const Duration(milliseconds: 2000));

    final prefs = await SharedPreferences.getInstance();
    final lastUid = prefs.getString(_lastUserKey);

    if (lastUid != null) {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      final biometricsEnabled =
          prefs.getBool('biometrics_enabled_$lastUid') ?? false;

      if (canCheck && isSupported && biometricsEnabled) {
        try {
          final authenticated = await _auth.authenticate(
            localizedReason: 'Authenticate to access Atlas',
          );

          if (authenticated) {
            final hasPrefsResult = await getIt<HasPreferencesUseCase>()(
              lastUid,
            );
            final hasPrefs = hasPrefsResult.fold((_) => false, (v) => v);

            if (!isClosed) {
              if (hasPrefs) {
                emit(SplashNavigateToHome());
              } else {
                emit(SplashNavigateToPreferences());
              }
            }
          } else {
            await prefs.remove(_lastUserKey);
            if (!isClosed) emit(SplashShowBackground());
          }
          return;
        } catch (e) {
          if (!isClosed) emit(SplashNavigateToSignin());
          return;
        }
      }
    }

    if (!isClosed) emit(SplashShowBackground());
  }

  void navigateToSignin() => emit(SplashNavigateToSignin());
  void navigateToHome() => emit(SplashNavigateToHome());
}
