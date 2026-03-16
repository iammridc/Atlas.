import 'package:atlas/core/consts/app_colors.dart';
import 'package:atlas/core/injections/injections.dart';
import 'package:atlas/core/router/app_router.dart';
import 'package:atlas/core/utils/app_snackbar.dart';
import 'package:atlas/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:atlas/features/auth/presentation/bloc/auth_state.dart';
import 'package:atlas/features/preferences/domain/entities/category_entity.dart';
import 'package:atlas/features/preferences/presentation/bloc/preferences_cubit.dart';
import 'package:atlas/features/preferences/presentation/bloc/preferences_state.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class PreferencesPage extends StatelessWidget {
  const PreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<PreferencesCubit>()..loadCategories(),
        ),
        BlocProvider.value(value: getIt<AuthCubit>()),
      ],
      child: const _InterestsView(),
    );
  }
}

class _InterestsView extends StatelessWidget {
  const _InterestsView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<PreferencesCubit, PreferencesState>(
      listener: (context, state) {
        if (state is PreferencesSaved) {
          context.router.replaceAll([
            HomeRoute(categoryTypes: state.categoryTypes),
          ]);
        }
        if (state is InterestsError) {
          AppSnackbar.show(
            context,
            message: state.message,
            type: SnackbarType.error,
          );
        }
      },
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pick Categories',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark ? Colors.white54 : Colors.black45,
                          height: 1,
                        ),
                        children: [
                          const TextSpan(
                            text:
                                'Choose precisely to personalise your experience, ',
                          ),
                          TextSpan(
                            text: 'or set it up later.',
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black54,
                              decoration: TextDecoration.underline,
                              decorationColor: isDark
                                  ? Colors.white54
                                  : Colors.black54,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => context.router.replaceAll([
                                HomeRoute(categoryTypes: []),
                              ]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: BlocBuilder<PreferencesCubit, PreferencesState>(
                  builder: (context, state) {
                    if (state is PreferencesLoading ||
                        state is PreferencesInitial) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is InterestsError) {
                      return Center(
                        child: Text(
                          state.message,
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      );
                    }

                    if (state is PreferencesLoaded) {
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                        itemCount: state.groupedCategories.length,
                        itemBuilder: (context, index) {
                          final group = state.groupedCategories.keys.elementAt(
                            index,
                          );
                          final categories = state.groupedCategories[group]!;
                          return _GroupSection(
                            group: group,
                            categories: categories,
                            selected: state.selected,
                            isDark: isDark,
                          );
                        },
                      );
                    }

                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
            ],
          ),
        ),

        bottomNavigationBar: BlocBuilder<PreferencesCubit, PreferencesState>(
          builder: (context, interestsState) {
            final isLoaded = interestsState is PreferencesLoaded;
            final isSaving = interestsState is PreferencesSaving;
            final selectedCount = isLoaded ? interestsState.selected.length : 0;

            return Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.backgroundDark
                    : AppColors.backgroundLight,
              ),
              child: BlocBuilder<AuthCubit, AuthState>(
                builder: (context, authState) {
                  final uid = authState is AuthAuthenticated
                      ? authState.user.id
                      : authState is AuthNeedsPreferences
                      ? authState.user.id
                      : null;

                  return SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed:
                          (!isLoaded ||
                              isSaving ||
                              selectedCount == 0 ||
                              uid == null)
                          ? null
                          : () => context
                                .read<PreferencesCubit>()
                                .savePreferences(uid),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? AppColors.appPrimaryWhite
                            : AppColors.appPrimaryBlack,
                        foregroundColor: isDark
                            ? AppColors.appPrimaryBlack
                            : AppColors.appPrimaryWhite,
                        disabledBackgroundColor: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        elevation: 0,
                      ),
                      child: isSaving
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDark ? Colors.black : Colors.white,
                              ),
                            )
                          : Text(
                              selectedCount == 0
                                  ? 'Select interests to continue'
                                  : 'Save $selectedCount interest${selectedCount == 1 ? '' : 's'}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GroupSection extends StatelessWidget {
  final String group;
  final List<CategoryEntity> categories;
  final Set<String> selected;
  final bool isDark;

  const _GroupSection({
    required this.group,
    required this.categories,
    required this.selected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, top: 18),
          child: Text(
            group.toUpperCase(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.appPrimaryWhite
                  : AppColors.appPrimaryBlack,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((cat) {
            final isSelected = selected.contains(cat.id);
            return GestureDetector(
              onTap: () => context.read<PreferencesCubit>().toggle(cat.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? Colors.white : Colors.black)
                      : (isDark
                            ? Colors.white.withOpacity(0.07)
                            : Colors.black.withOpacity(0.07)),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : (isDark
                              ? Colors.black.withOpacity(0.07)
                              : Colors.white.withOpacity(0.07)),
                  ),
                ),
                child: Text(
                  cat.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? (isDark ? Colors.black : Colors.white)
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
