import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/constants/route_names.dart';
import '../core/constants/app_constants.dart';
import '../core/widgets/user_avatar.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.currentUser;
          return Column(
            children: [
              const SizedBox(height: 24),
              UserAvatar(
                avatarUrl: user?.avatarUrl,
                displayName: user?.fullName,
                size: 80,
              ),
              const SizedBox(height: 16),
              Text(
                user?.fullName ?? 'Driver',
                style: AppTextStyles.headlineMedium,
              ),
              Text(
                user?.phone ?? AppConstants.countryCode,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.edit, color: AppColors.primary),
                      title: const Text('Edit profile'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          Navigator.of(context).pushNamed(RouteNames.editProfile),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.settings, color: AppColors.primary),
                      title: const Text('Settings'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          Navigator.of(context).pushNamed(RouteNames.settings),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
