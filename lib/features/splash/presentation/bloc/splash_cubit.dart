import 'package:flutter_bloc/flutter_bloc.dart';
import 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  SplashCubit() : super(SplashInitial());

  Future<void> init() async {
    emit(SplashLogoVisible());
    await Future.delayed(const Duration(milliseconds: 2000));
    emit(SplashShowBackground());
  }

  void navigateToSignin() {
    emit(SplashNavigateToSignin());
  }
}
