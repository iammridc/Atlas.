import 'package:atlas/core/injections/injections.dart';
import 'package:atlas/core/widgets/transient_error_placeholder.dart';
import 'package:atlas/features/home/presentation/bloc/hot_places_cubit.dart';
import 'package:atlas/features/home/presentation/bloc/hot_places_state.dart';
import 'package:atlas/features/home/presentation/widgets/recommendation_card.dart';
import 'package:atlas/features/profile/domain/repositories/profile_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HotPlacesSection extends StatefulWidget {
  const HotPlacesSection({super.key});

  @override
  State<HotPlacesSection> createState() => _HotPlacesSectionState();
}

class _HotPlacesSectionState extends State<HotPlacesSection> {
  late final Future<String?> _usernameFuture;

  @override
  void initState() {
    super.initState();
    _usernameFuture = _loadUsername();
  }

  Future<String?> _loadUsername() async {
    final result = await getIt<ProfileRepository>().getProfileSummary();
    return result.fold((_) => null, (profile) {
      final username = profile.username.trim();
      return username.isEmpty ? null : username;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<HotPlacesCubit, HotPlacesState>(
      builder: (context, state) {
        final places = state is HotPlacesLoaded ? state.places : const [];
        final isLoading = state is HotPlacesLoading;
        final isError = state is HotPlacesError;
        final isReloading = state is HotPlacesError && state.isReloading;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<String?>(
              future: _usernameFuture,
              builder: (context, snapshot) {
                final username = snapshot.data?.trim();
                if (username == null || username.isEmpty) {
                  return const SizedBox(height: 16);
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 2),
                  child: Text(
                    'Welcome, $username!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                );
              },
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 4),
              child: Text(
                'Trending today in Atlas',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            if (isLoading)
              const SizedBox(
                height: 260,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (isError)
              SizedBox(
                height: 250,
                child: isReloading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: isDark ? Colors.white38 : Colors.black38,
                          strokeWidth: 2,
                        ),
                      )
                    : const TransientErrorPlaceholder(
                        icon: CupertinoIcons.flame,
                        title: 'Hot places unavailable',
                        message: 'Pull down from the top to refresh.',
                      ),
              )
            else if (places.isEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.flame,
                      size: 54,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No community favourites yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth - 48).clamp(
                    0.0,
                    360.0,
                  );

                  return SizedBox(
                    height: 260,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: places.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 24),
                      itemBuilder: (context, index) => RecommendationCard(
                        recommendation: places[index],
                        width: cardWidth,
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
