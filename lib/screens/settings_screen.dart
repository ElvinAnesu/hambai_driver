import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/constants/route_names.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              return SwitchListTile(
                title: const Text('Notifications'),
                subtitle: const Text('Ride and session reminders'),
                value: settings.notificationsEnabled,
                onChanged: (v) => settings.setNotificationsEnabled(v),
                activeColor: AppColors.primary,
              );
            },
          ),
          const Divider(height: 1),
          Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              return ListTile(
                title: const Text('Theme'),
                subtitle: Text(
                  settings.themeMode == ThemeMode.light
                      ? 'Light'
                      : settings.themeMode == ThemeMode.dark
                          ? 'Dark'
                          : 'System',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemePicker(context, settings),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            title: Text(
              'Log out',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
            onTap: () => _logout(context),
          ),
          ListTile(
            title: Text(
              'Delete account',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.error,
              ),
            ),
            onTap: () => _deleteAccount(context),
          ),
        ],
      ),
    );
  }

  void _showThemePicker(BuildContext context, SettingsProvider settings) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Light'),
              onTap: () {
                settings.setThemeMode(ThemeMode.light);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Dark'),
              onTap: () {
                settings.setThemeMode(ThemeMode.dark);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('System'),
              onTap: () {
                settings.setThemeMode(ThemeMode.system);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<AuthProvider>().logout();
      if (!context.mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        RouteNames.login,
        (route) => false,
      );
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This will remove your driver account and all local data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<AuthProvider>().deleteAccount();
      if (!context.mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        RouteNames.login,
        (route) => false,
      );
    }
  }
}
