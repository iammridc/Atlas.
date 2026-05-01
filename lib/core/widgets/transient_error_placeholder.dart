import 'package:atlas/core/consts/app_colors.dart';
import 'package:flutter/material.dart';

class TransientErrorPlaceholder extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final double iconSize;

  const TransientErrorPlaceholder({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.iconSize = 52,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize, color: AppColors.errorColor),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.appPrimaryBlack,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
                fontSize: 15,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScrollableTransientErrorPlaceholder extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final double iconSize;

  const ScrollableTransientErrorPlaceholder({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.iconSize = 52,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          children: [
            SizedBox(
              height: constraints.maxHeight,
              child: TransientErrorPlaceholder(
                icon: icon,
                title: title,
                message: message,
                iconSize: iconSize,
              ),
            ),
          ],
        );
      },
    );
  }
}
