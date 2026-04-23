import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HomeBottomNavBarItem {
  final IconData icon;
  final String label;

  const HomeBottomNavBarItem({required this.icon, required this.label});
}

class HomeBottomNavBar extends StatelessWidget {
  final List<HomeBottomNavBarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const HomeBottomNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = CupertinoDynamicColor.resolve(
      (isDark ? CupertinoColors.black : CupertinoColors.systemBackground)
          .withValues(alpha: isDark ? 0.78 : 0.84),
      context,
    );
    final borderColor = CupertinoDynamicColor.resolve(
      (isDark ? CupertinoColors.white : CupertinoColors.separator).withValues(
        alpha: isDark ? 0.1 : 0.16,
      ),
      context,
    );
    final selectedBackgroundColor = CupertinoDynamicColor.resolve(
      (isDark ? CupertinoColors.systemGrey4 : CupertinoColors.systemGrey5)
          .withValues(alpha: isDark ? 0.42 : 0.95),
      context,
    );
    final activeColor = CupertinoDynamicColor.resolve(
      CupertinoColors.label,
      context,
    );
    final inactiveColor = CupertinoDynamicColor.resolve(
      CupertinoColors.secondaryLabel,
      context,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == selectedIndex;
              final itemColor = isSelected ? activeColor : inactiveColor;

              return Expanded(
                child: Semantics(
                  button: true,
                  selected: isSelected,
                  label: item.label,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onSelected(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? selectedBackgroundColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(item.icon, size: 20, color: itemColor),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: itemColor,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
