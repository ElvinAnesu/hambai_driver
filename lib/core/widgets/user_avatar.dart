import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.avatarUrl,
    this.displayName,
    this.size = 56,
  });

  final String? avatarUrl;
  final String? displayName;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(avatarUrl!),
      );
    }
    final initial = displayName != null && displayName!.trim().isNotEmpty
        ? displayName!.trim().substring(0, 1).toUpperCase()
        : '?';
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.primaryLight,
      child: Text(
        initial,
        style: AppTextStyles.headlineMedium.copyWith(
          color: AppColors.primary,
        ),
      ),
    );
  }
}
