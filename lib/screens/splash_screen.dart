import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/constants/route_names.dart';
import '../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _navigate());
  }

  Future<void> _navigate() async {
    final auth = context.read<AuthProvider>();
    final settings = context.read<SettingsProvider>();
    if (!auth.isInitialized) await auth.initialize();
    if (!settings.isInitialized) await settings.initialize();
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final nav = Navigator.of(context);
    if (!auth.hasCompletedOnboarding) {
      nav.pushReplacementNamed(RouteNames.onboarding);
      return;
    }
    if (!auth.isAuthenticated) {
      nav.pushReplacementNamed(RouteNames.login);
      return;
    }
    if (auth.currentUser?.fullName == null ||
        auth.currentUser!.fullName!.trim().isEmpty) {
      nav.pushReplacementNamed(RouteNames.completeProfile);
      return;
    }
    nav.pushReplacementNamed(RouteNames.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryVariant],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.directions_bus_rounded,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                Text(
                  AppConstants.appName,
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
