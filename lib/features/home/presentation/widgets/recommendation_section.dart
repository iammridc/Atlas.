import 'package:atlas/core/consts/app_colors.dart';
import 'package:atlas/features/home/domain/entity/recommendation_entity.dart';
import 'package:atlas/features/home/presentation/bloc/recommendation_cubit.dart';
import 'package:atlas/features/home/presentation/widgets/recommendation_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RecommendationsSection extends StatelessWidget {
  final List<RecommendationEntity> recommendations;
  final bool isLoadingMore;
  final bool hasError;
  final bool isReloading;

  const RecommendationsSection({
    super.key,
    required this.recommendations,
    this.isLoadingMore = false,
    this.hasError = false,
    this.isReloading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            'Picked For You',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ),

        if (hasError || recommendations.isEmpty)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isReloading
                ? null
                : () => context.read<RecommendationsCubit>().reload(),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(26),
              ),
              child: isReloading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: isDark ? Colors.white38 : Colors.black38,
                        strokeWidth: 2,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.exclamationmark_circle,
                          size: 60,
                          color: AppColors.errorColor,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Error occured.\nTry to update your preferences.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
            ),
          )
        else
          SizedBox(
            height: 260,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: recommendations.length + 1,
              separatorBuilder: (_, index) => const SizedBox(width: 24),
              itemBuilder: (context, index) {
                if (index == recommendations.length) {
                  return _LoadMoreButton(isLoading: isLoadingMore);
                }
                return RecommendationCard(
                  recommendation: recommendations[index],
                );
              },
            ),
          ),

        const SizedBox(height: 16),
      ],
    );
  }
}

class _LoadMoreButton extends StatelessWidget {
  final bool isLoading;

  const _LoadMoreButton({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: isLoading
          ? null
          : () => context.read<RecommendationsCubit>().loadMore(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Container(
          width: 360,
          height: 250,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: Icon(
                        CupertinoIcons.add_circled,
                        color: isDark
                            ? AppColors.appPrimaryWhite
                            : AppColors.appPrimaryBlack,
                        size: 64,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
