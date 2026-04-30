import 'package:atlas/core/consts/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ProfilePageHeader extends StatelessWidget {
  final String title;
  final IconData? actionIcon;
  final String? actionTooltip;
  final VoidCallback? onActionTap;

  const ProfilePageHeader({
    super.key,
    required this.title,
    this.actionIcon,
    this.actionTooltip,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark
        ? AppColors.appPrimaryWhite
        : AppColors.appPrimaryBlack;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 6),
      child: Row(
        children: [
          ProfileHeaderIconButton(
            icon: CupertinoIcons.chevron_left,
            tooltip: 'Back',
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: titleColor,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
          if (actionIcon != null && onActionTap != null) ...[
            const SizedBox(width: 12),
            ProfileHeaderIconButton(
              icon: actionIcon!,
              tooltip: actionTooltip ?? title,
              onTap: onActionTap!,
            ),
          ],
        ],
      ),
    );
  }
}

class ProfileHeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? foregroundColor;
  final Color? backgroundColor;

  const ProfileHeaderIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.foregroundColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color:
                backgroundColor ??
                (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            size: 22,
            color:
                foregroundColor ??
                (isDark
                    ? AppColors.appPrimaryWhite
                    : AppColors.appPrimaryBlack),
          ),
        ),
      ),
    );
  }
}
