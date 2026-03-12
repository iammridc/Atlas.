import 'package:atlas/core/router/app_router.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class SigninPage extends StatelessWidget {
  const SigninPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.router.replace(const HomeRoute()),
          child: const Text('Login'),
        ),
      ),
    );
  }
}
