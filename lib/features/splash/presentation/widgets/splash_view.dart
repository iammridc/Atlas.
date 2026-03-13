import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:atlas/core/consts/app_colors.dart';
import 'package:atlas/features/splash/presentation/bloc/splash_cubit.dart';
import 'package:atlas/features/splash/presentation/bloc/splash_state.dart';
import 'package:atlas/features/splash/presentation/widgets/splash_slider.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SplashCubit>().state;
    final showLogo = state is SplashLogoVisible;
    final showBackground =
        state is SplashShowBackground ||
        state is SplashNavigateToSignin ||
        state is SplashNavigateToHome;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: Stack(
        children: [
          AnimatedOpacity(
            opacity: showBackground ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 1250),
            curve: Curves.easeIn,
            child: Stack(
              children: [
                SizedBox(
                  width: screenWidth,
                  height: screenHeight,
                  child: Image.asset(
                    'assets/pngs/splash_background.png',
                    fit: BoxFit.cover,
                  ),
                ),
                Container(
                  width: screenWidth,
                  height: screenHeight,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 145,
                  left: 18,
                  right: 18,
                  child: AnimatedOpacity(
                    opacity: showBackground ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOut,
                    child: AnimatedSlide(
                      offset: showBackground
                          ? Offset.zero
                          : const Offset(-0.1, 0),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOut,
                      child: const Text(
                        'Some places\nchange you\nforever.',
                        style: TextStyle(
                          color: AppColors.appPrimaryWhite,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 120,
                  left: 18,
                  right: 18,
                  child: AnimatedOpacity(
                    opacity: showBackground ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOut,
                    child: AnimatedSlide(
                      offset: showBackground
                          ? Offset.zero
                          : const Offset(-0.1, 0),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOut,
                      child: const Text(
                        'Discover, plan and explore with Atlas.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    opacity: showBackground ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOut,
                    child: AnimatedSlide(
                      offset: showBackground
                          ? Offset.zero
                          : const Offset(0, 0.5),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOut,
                      child: SlideToUnlock(
                        onSlideComplete: () {
                          context.read<SplashCubit>().navigateToSignin();
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedOpacity(
            opacity: showLogo ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 750),
            curve: Curves.easeOut,
            child: Center(
              child: SvgPicture.asset(
                'assets/svgs/logo.svg',
                width: 87,
                height: 87,
                colorFilter: ColorFilter.mode(
                  isDark
                      ? AppColors.appPrimaryWhite
                      : AppColors.appPrimaryBlack,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
