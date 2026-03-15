import 'package:atlas/features/home/domain/entity/recommendation_entity.dart';
import 'package:atlas/features/home/presentation/bloc/recommendation_cubit.dart';
import 'package:atlas/features/home/presentation/widgets/recommendation_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RecommendationsSection extends StatelessWidget {
  final List<RecommendationEntity> recommendations;
  final bool isLoadingMore;

  const RecommendationsSection({
    super.key,
    required this.recommendations,
    this.isLoadingMore = false,
  });

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('No recommendations yet.')),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            'Recommended for You',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 260,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: recommendations.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index == recommendations.length) {
                return _LoadMoreButton(isLoading: isLoadingMore);
              }
              return RecommendationCard(recommendation: recommendations[index]);
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
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 200,
          height: 260,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.08),
            ),
          ),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.07),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add,
                        color: isDark ? Colors.white : Colors.black,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Load more',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '10 new places',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
