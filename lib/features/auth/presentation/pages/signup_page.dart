import 'package:atlas/core/router/app_router.dart';
import 'package:atlas/core/utils/app_snackbar.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:atlas/core/injections/injections.dart';
import 'package:atlas/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:atlas/features/auth/presentation/bloc/auth_state.dart';
import 'package:atlas/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:atlas/features/auth/presentation/widgets/auth_button.dart';

@RoutePage()
class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<AuthCubit>(),
      child: const _SignupView(),
    );
  }
}

class _SignupView extends StatefulWidget {
  const _SignupView();

  @override
  State<_SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<_SignupView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_emailFocusNode);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthRegistered) {
          context.router.replace(const SigninRoute());
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AppSnackbar.show(
              context,
              message: 'Account has been successfully created!',
              type: SnackbarType.success,
            );
          });
        }
        if (state is AuthError) {
          AppSnackbar.show(
            context,
            message: state.message,
            type: SnackbarType.error,
          );
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        extendBodyBehindAppBar: true,
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              reverse: true,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: MediaQuery.of(context).padding.top,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 40),
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeIn,
                            opacity: keyboardVisible ? 0.0 : 1.0,
                            child: IgnorePointer(
                              child: SizedBox(
                                height: keyboardVisible ? 0 : 144,
                                child: Center(
                                  child: SvgPicture.asset(
                                    'assets/svgs/logo.svg',
                                    width: 64,
                                    height: 64,
                                    colorFilter: ColorFilter.mode(
                                      isDark ? Colors.white : Colors.black,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const Spacer(),

                          Text(
                            'New\nHorizons.',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                              height: 1,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'Thousands of places. One account.',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.white38 : Colors.black38,
                              fontWeight: FontWeight.w300,
                              height: 1,
                            ),
                          ),

                          const SizedBox(height: 12),

                          AuthTextField(
                            hint: 'Email',
                            controller: _emailController,
                            focusNode: _emailFocusNode,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          AuthTextField(
                            hint: 'Password',
                            controller: _passwordController,
                            isPassword: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          AuthTextField(
                            hint: 'Confirm Password',
                            controller: _confirmPasswordController,
                            isPassword: true,
                            matchController: _passwordController,
                            validator: (value) {
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          BlocBuilder<AuthCubit, AuthState>(
                            builder: (context, state) {
                              return AuthButton(
                                label: 'Create Account',
                                isLoading: state is AuthLoading,
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    context.read<AuthCubit>().signUp(
                                      email: _emailController.text.trim(),
                                      password: _passwordController.text.trim(),
                                    );
                                  }
                                },
                              );
                            },
                          ),

                          const SizedBox(height: 16),

                          Center(
                            child: GestureDetector(
                              onTap: () => context.router.back(),
                              child: Text(
                                'Already have an account? Sign in',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black54,
                                  fontWeight: FontWeight.w400,
                                  decoration: TextDecoration.underline,
                                  decorationColor: isDark
                                      ? Colors.white38
                                      : Colors.black54,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(
                            height: keyboardVisible
                                ? MediaQuery.of(context).viewInsets.bottom + 16
                                : 32,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
