import 'package:atlas/core/router/app_router.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:atlas/core/injections/injections.dart';
import 'package:atlas/features/splash/presentation/bloc/splash_cubit.dart';
import 'package:atlas/features/splash/presentation/bloc/splash_state.dart';
import 'package:atlas/features/splash/presentation/widgets/splash_view.dart';

@RoutePage()
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SplashCubit>()..init(),
      child: BlocListener<SplashCubit, SplashState>(
        listener: (context, state) {
          if (state is SplashNavigateToSignin) {
            context.router.replace(const SigninRoute());
          } else if (state is SplashNavigateToHome) {
            context.router.replace(const HomeRoute());
          }
        },
        child: SplashView(),
      ),
    );
  }
}
