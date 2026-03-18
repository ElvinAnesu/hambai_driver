import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/constants/route_names.dart';
import '../core/constants/app_constants.dart';
import '../core/widgets/user_avatar.dart';
import '../providers/auth_provider.dart';
import '../providers/driver_session_provider.dart';
import '../providers/driver_history_provider.dart';
import 'home_dashboard_screen.dart';
import 'driver_history_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const List<Widget> _tabs = [
    HomeDashboardScreen(),
    DriverHistoryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _currentIndex == 0
            ? Consumer<AuthProvider>(
                builder: (context, auth, _) => Text(
                  auth.currentUser?.fullName ?? 'Driver',
                ),
              )
            : Text(
                _currentIndex == 1 ? 'History' : 'Profile',
              ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_currentIndex == 0)
            Consumer<DriverSessionProvider>(
              builder: (context, session, _) {
                if (session.hasActiveSession) {
                  return IconButton(
                    icon: const Icon(Icons.directions_bus),
                    onPressed: () =>
                        Navigator.of(context).pushNamed(RouteNames.activeRide),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                final user = auth.currentUser;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
                  color: AppColors.secondary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UserAvatar(
                        avatarUrl: user?.avatarUrl,
                        displayName: user?.fullName,
                        size: 64,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user?.fullName ?? 'Driver',
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        user?.phone ?? AppConstants.countryCode,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                setState(() => _currentIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('History'),
              onTap: () {
                context.read<DriverHistoryProvider>().loadSessions();
                setState(() => _currentIndex = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                setState(() => _currentIndex = 2);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed(RouteNames.settings);
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Terms'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed(RouteNames.terms);
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacy'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed(RouteNames.privacy);
              },
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Help'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed(RouteNames.help);
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          if (i == 1) {
            context.read<DriverHistoryProvider>().loadSessions();
          }
          setState(() => _currentIndex = i);
        },
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
