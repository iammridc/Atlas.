import 'package:atlas/features/home/presentation/widgets/hot_places_section.dart';
import 'package:atlas/features/home/presentation/widgets/map_section.dart';
import 'package:atlas/features/home/presentation/bloc/recommendation_cubit.dart';
import 'package:atlas/features/home/presentation/bloc/recommendations_state.dart';
import 'package:atlas/features/home/presentation/widgets/recommendation_section.dart';
import 'package:atlas/core/injections/injections.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class HomePage extends StatelessWidget {
  final List<String> categoryTypes;

  const HomePage({super.key, required this.categoryTypes});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RecommendationsCubit>(),
      child: _HomeView(categoryTypes: categoryTypes),
    );
  }
}

class _HomeView extends StatefulWidget {
  final List<String> categoryTypes;

  const _HomeView({required this.categoryTypes});

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  @override
  void initState() {
    super.initState();
    context.read<RecommendationsCubit>().loadRecommendations(
      widget.categoryTypes,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).padding.top),
          ),
          const SliverToBoxAdapter(child: HotPlacesSection()),

          SliverToBoxAdapter(
            child: BlocBuilder<RecommendationsCubit, RecommendationsState>(
              builder: (context, state) {
                return switch (state) {
                  RecommendationsLoading() => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  RecommendationsLoaded(
                    recommendations: final places,
                    isLoadingMore: final isLoadingMore,
                  ) =>
                    RecommendationsSection(
                      recommendations: places,
                      isLoadingMore: isLoadingMore,
                    ),
                  RecommendationsError(isReloading: final isReloading) =>
                    RecommendationsSection(
                      recommendations: [],
                      hasError: true,
                      isReloading: isReloading,
                    ),
                  _ => const SizedBox.shrink(),
                };
              },
            ),
          ),

          const SliverToBoxAdapter(child: MapSection()),
        ],
      ),
    );
  }
}
