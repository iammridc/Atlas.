import 'package:atlas/core/injections/injections.dart';
import 'package:atlas/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:atlas/features/auth/presentation/bloc/auth_state.dart';
import 'package:atlas/core/router/app_router.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<AuthCubit>(),
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            context.router.replaceAll([const SigninRoute()]);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Atlas'),
            actions: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  onPressed: () => context.read<AuthCubit>().signOut(),
                ),
              ),
            ],
          ),
          body: const Center(child: Text('Home')),
        ),
      ),
    );
  }
}
