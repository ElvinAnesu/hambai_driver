import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/route_names.dart';
import 'core/supabase/supabase_client.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/driver_session_provider.dart';
import 'providers/driver_history_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/complete_profile_screen.dart';
import 'screens/main_shell.dart';
import 'screens/select_route_screen.dart';
import 'screens/active_ride_screen.dart';
import 'screens/driver_code_display_screen.dart';
import 'screens/trip_summary_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/help_screen.dart';
import 'models/driver_session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DriverSupabase.initialize();
  runApp(const HambaiDriverApp());
}

class HambaiDriverApp extends StatelessWidget {
  const HambaiDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => DriverSessionProvider()),
        ChangeNotifierProvider(create: (_) => DriverHistoryProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Hambai Driver',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settings.themeMode,
            initialRoute: RouteNames.splash,
            routes: {
              RouteNames.splash: (_) => const SplashScreen(),
              RouteNames.onboarding: (_) => const OnboardingScreen(),
              RouteNames.login: (_) => const LoginScreen(),
              RouteNames.otp: (_) => const OtpScreen(),
              RouteNames.completeProfile: (_) => const CompleteProfileScreen(),
              RouteNames.home: (_) => const MainShell(),
              RouteNames.selectRoute: (_) => const SelectRouteScreen(),
              RouteNames.activeRide: (_) => const ActiveRideScreen(),
              RouteNames.driverCodeDisplay: (_) =>
                  const DriverCodeDisplayScreen(),
              RouteNames.profile: (_) => const MainShell(), // same shell, tab
              RouteNames.history: (_) => const MainShell(),
              RouteNames.settings: (_) => const SettingsScreen(),
              RouteNames.incidences: (_) => const HelpScreen(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == RouteNames.tripSummary) {
                final session = settings.arguments;
                if (session != null) {
                  return MaterialPageRoute<void>(
                    builder: (_) => TripSummaryScreen(session: session as DriverSession),
                  );
                }
              }
              return null;
            },
          );
        },
      ),
    );
  }
}
