import 'package:atlas/core/router/app_router.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:atlas/core/injections/injections.dart';
import 'package:atlas/features/splash/presentation/bloc/splash_cubit.dart';
import 'package:atlas/features/splash/presentation/bloc/splash_state.dart';

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
        child: const _SplashView(),
      ),
    );
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SplashCubit>().state;
    final showText =
        state is SplashAnimating && (state).showText ||
        state is SplashNavigateToSignin ||
        state is SplashNavigateToHome;

    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeInOut,
            // logo center position: screen center - 120px, then moves up 120px
            top: showText
                ? screenHeight / 2 -
                      240 // moved up 120px from start
                : screenHeight / 2 - 120, // starting position (center - 120px)
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 75),
                SvgPicture.asset(
                  'assets/svgs/logo.svg',
                  width: 90,
                  height: 90,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),

                const SizedBox(height: 16),

                AnimatedOpacity(
                  opacity: showText ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOut,
                  child: AnimatedSlide(
                    offset: showText ? Offset.zero : const Offset(0, 0.3),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOut,
                    child: const Text(
                      'Atlas.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                AnimatedOpacity(
                  opacity: showText ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOut,
                  child: AnimatedSlide(
                    offset: showText ? Offset.zero : const Offset(0, 0.3),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOut,
                    child: const Text(
                      'Your world, simplified.',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 18,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
