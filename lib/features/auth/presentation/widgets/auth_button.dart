import 'package:flutter/material.dart';
import 'package:atlas/core/consts/app_colors.dart';

class AuthButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;

  const AuthButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: _child(isDark),
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.appPrimaryWhite
                    : AppColors.appPrimaryBlack,
                foregroundColor: isDark
                    ? AppColors.appPrimaryBlack
                    : AppColors.appPrimaryWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                elevation: 0,
              ),
              child: _child(isDark),
            ),
    );
  }

  Widget _child(bool isDark) {
    return isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isDark
                  ? AppColors.appPrimaryBlack
                  : AppColors.appPrimaryWhite,
            ),
          )
        : Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          );
  }
}
