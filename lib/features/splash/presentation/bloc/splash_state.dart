abstract class SplashState {}

class SplashInitial extends SplashState {}

class SplashAnimating extends SplashState {
  final bool showText;
  SplashAnimating({this.showText = false});
}

class SplashNavigateToHome extends SplashState {}

class SplashNavigateToSignin extends SplashState {}
