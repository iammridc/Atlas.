import 'package:atlas/core/consts/app_colors.dart';
import 'package:atlas/features/profile/domain/entities/profile_gamification_entity.dart';
import 'package:atlas/features/profile/presentation/widgets/profile_page_header.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AchievementsPage extends StatelessWidget {
  final ProfileGamificationEntity gamification;

  const AchievementsPage({super.key, required this.gamification});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final badges = [...gamification.badges]
      ..sort((a, b) {
        if (a.isUnlocked != b.isUnlocked) return a.isUnlocked ? -1 : 1;
        return b.completion.compareTo(a.completion);
      });

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ProfilePageHeader(title: 'Achievements'),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                itemCount: badges.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _AchievementCard(badge: badges[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final ProfileBadgeEntity badge;

  const _AchievementCard({required this.badge});

  @override
  Widget build(BuildContext context) {
    final progress = badge.progress.clamp(0, badge.target);

    return _SurfaceBlock(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _IconBubble(
            icon: _iconForKey(badge.iconKey),
            active: badge.isUnlocked,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        badge.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _softSurfaceColor(context),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$progress/${badge.target}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _secondaryColor(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  badge.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _secondaryColor(context),
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: badge.completion,
                    minHeight: 6,
                    backgroundColor: _trackColor(context),
                    valueColor: AlwaysStoppedAnimation(
                      _foregroundColor(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  final IconData icon;
  final bool active;

  const _IconBubble({required this.icon, required this.active});

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundColor(context);
    final background = Theme.of(context).scaffoldBackgroundColor;

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? foreground : _softSurfaceColor(context),
      ),
      child: Icon(
        icon,
        size: 23,
        color: active ? background : foreground.withValues(alpha: 0.58),
      ),
    );
  }
}

class _SurfaceBlock extends StatelessWidget {
  final Widget child;

  const _SurfaceBlock({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(28);

    return Material(
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFFF0F0F0),
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.16 : 0.08),
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    );
  }
}

IconData _iconForKey(String key) {
  return switch (key) {
    'beach' => CupertinoIcons.sun_max,
    'border' => Icons.compare_arrows_rounded,
    'city' => CupertinoIcons.building_2_fill,
    'city_sampler' => CupertinoIcons.square_grid_2x2,
    'country' => CupertinoIcons.globe,
    'food' => Icons.restaurant_rounded,
    'gem' => Icons.diamond_outlined,
    'guide' => CupertinoIcons.hand_thumbsup,
    'museum' => CupertinoIcons.photo_on_rectangle,
    'photo' => CupertinoIcons.camera,
    'photo_review' => CupertinoIcons.photo,
    'places' => CupertinoIcons.location_solid,
    'rating' => CupertinoIcons.star_fill,
    'review' => CupertinoIcons.text_bubble,
    'route' => CupertinoIcons.map,
    'spark' => CupertinoIcons.sparkles,
    'story' => CupertinoIcons.book,
    'style' => CupertinoIcons.slider_horizontal_3,
    'tag' => CupertinoIcons.tag,
    'weekend' => CupertinoIcons.calendar,
    _ => CupertinoIcons.star,
  };
}

Color _foregroundColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AppColors.appPrimaryWhite
      : AppColors.appPrimaryBlack;
}

Color _secondaryColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.white60
      : Colors.black54;
}

Color _softSurfaceColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.white.withValues(alpha: 0.08)
      : Colors.black.withValues(alpha: 0.05);
}

Color _trackColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.white.withValues(alpha: 0.12)
      : Colors.black.withValues(alpha: 0.08);
}
