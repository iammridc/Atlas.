import 'package:flutter_bloc/flutter_bloc.dart';
import 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  SplashCubit() : super(SplashInitial());

  Future<void> init() async {
    emit(SplashAnimating(showText: false));

    await Future.delayed(const Duration(milliseconds: 2000)); // 2 sec delay
    emit(SplashAnimating(showText: true));

    await Future.delayed(const Duration(milliseconds: 5000)); // 5 sec delay
    emit(SplashNavigateToSignin());
  }
}
