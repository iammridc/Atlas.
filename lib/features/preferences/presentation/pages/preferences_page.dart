import 'package:atlas/core/consts/app_colors.dart';
import 'package:atlas/core/injections/injections.dart';
import 'package:atlas/core/router/app_router.dart';
import 'package:atlas/core/utils/app_snackbar.dart';
import 'package:atlas/features/preferences/domain/entities/category_entity.dart';
import 'package:atlas/features/preferences/presentation/bloc/preferences_cubit.dart';
import 'package:atlas/features/preferences/presentation/bloc/preferences_state.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class PreferencesPage extends StatelessWidget {
  final String uid;
  final bool replaceStackOnSave;
  final bool showSkipAction;
  final bool allowEmptySelection;
  final List<String> initialSelectedCategoryIds;

  const PreferencesPage({
    super.key,
    required this.uid,
    this.replaceStackOnSave = true,
    this.showSkipAction = true,
    this.allowEmptySelection = false,
    this.initialSelectedCategoryIds = const [],
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PreferencesCubit>()
        ..loadCategories(initiallySelected: initialSelectedCategoryIds.toSet()),
      child: _InterestsView(
        uid: uid,
        replaceStackOnSave: replaceStackOnSave,
        showSkipAction: showSkipAction,
        allowEmptySelection: allowEmptySelection,
      ),
    );
  }
}

class _InterestsView extends StatelessWidget {
  final String uid;
  final bool replaceStackOnSave;
  final bool showSkipAction;
  final bool allowEmptySelection;

  const _InterestsView({
    required this.uid,
    required this.replaceStackOnSave,
    required this.showSkipAction,
    required this.allowEmptySelection,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<PreferencesCubit, PreferencesState>(
      listener: (context, state) {
        if (state is PreferencesSaved) {
          if (replaceStackOnSave) {
            context.router.replaceAll([
              HomeRoute(categoryTypes: state.categoryTypes),
            ]);
          } else {
            Navigator.of(context).pop(state.categoryTypes);
          }
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
                      'Make It Yours.',
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
                          if (showSkipAction)
                            TextSpan(
                              text: 'or set it up later.',
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black45,
                                decoration: TextDecoration.underline,
                                decorationColor: isDark
                                    ? Colors.white54
                                    : Colors.black45,
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
          builder: (context, state) {
            final isLoaded = state is PreferencesLoaded;
            final isSaving = state is PreferencesSaving;
            final selectedCount = isLoaded ? state.selected.length : 0;

            return Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 26),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.backgroundDark
                    : AppColors.backgroundLight,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed:
                      (!isLoaded ||
                          isSaving ||
                          (!allowEmptySelection && selectedCount == 0))
                      ? null
                      : () => context.read<PreferencesCubit>().savePreferences(
                          uid,
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? AppColors.appPrimaryWhite
                        : AppColors.appPrimaryBlack,
                    foregroundColor: isDark
                        ? AppColors.appPrimaryBlack
                        : AppColors.appPrimaryWhite,
                    disabledBackgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
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
                              ? (allowEmptySelection
                                    ? 'Save without preferences'
                                    : 'Choose your preferences to continue')
                              : 'Save $selectedCount preference${selectedCount == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
          padding: const EdgeInsets.only(bottom: 6, top: 22),
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
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? Colors.white : Colors.black)
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : Colors.black.withValues(alpha: 0.07)),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : (isDark
                              ? Colors.black.withValues(alpha: 0.07)
                              : Colors.white.withValues(alpha: 0.07)),
                  ),
                ),
                child: Text(
                  cat.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
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
