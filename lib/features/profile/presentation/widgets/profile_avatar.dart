import 'dart:convert';

import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double size;
  final bool canEdit;
  final VoidCallback onTap;

  const ProfileAvatar({
    super.key,
    required this.avatarUrl,
    required this.size,
    this.canEdit = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageProvider = _buildImageProvider(avatarUrl);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: canEdit ? onTap : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
          image: imageProvider == null
              ? null
              : DecorationImage(image: imageProvider, fit: BoxFit.cover),
        ),
        child: imageProvider == null
            ? Icon(
                Icons.person_rounded,
                size: size * 0.48,
                color: isDark ? Colors.white54 : Colors.black38,
              )
            : null,
      ),
    );
  }

  ImageProvider<Object>? _buildImageProvider(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.trim();

    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return NetworkImage(normalized);
    }

    if (normalized.startsWith('data:image')) {
      final parts = normalized.split(',');
      if (parts.length < 2) return null;
      try {
        return MemoryImage(base64Decode(parts.last));
      } catch (_) {
        return null;
      }
    }

    return null;
  }
}
