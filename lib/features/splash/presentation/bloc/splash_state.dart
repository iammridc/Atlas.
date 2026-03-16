// splash_state.dart

abstract class SplashState {}

class SplashInitial extends SplashState {}

class SplashLogoVisible extends SplashState {}

class SplashShowBackground extends SplashState {}

class SplashBiometricsFailed extends SplashState {}

class SplashNavigateToHome extends SplashState {
  final List<String> categoryTypes;
  SplashNavigateToHome(this.categoryTypes);
}

class SplashNavigateToSignin extends SplashState {}

class SplashNavigateToPreferences extends SplashState {
  final String uid; // 👈 added
  SplashNavigateToPreferences(this.uid);
}
