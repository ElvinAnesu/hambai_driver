import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/driver_session.dart';
import '../providers/driver_history_provider.dart';
import '../core/widgets/loading_indicator.dart';
import '../core/widgets/empty_state.dart';

/// Demo: stable display rides per session (matches active ride / trip summary).
int _demoRidesCollected(DriverSession s) {
  final hash = s.sessionId.hashCode.abs();
  return (hash % 11) + 3;
}

class DriverHistoryScreen extends StatefulWidget {
  const DriverHistoryScreen({super.key});

  @override
  State<DriverHistoryScreen> createState() => _DriverHistoryScreenState();
}

class _DriverHistoryScreenState extends State<DriverHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverHistoryProvider>().loadSessions();
    });
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year &&
        d.month == now.month &&
        d.day == now.day) {
      return 'Today ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DriverHistoryProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.sessions.isEmpty) {
          return const LoadingIndicator();
        }
        if (provider.sessions.isEmpty) {
          return const EmptyState(
            message: 'No past sessions yet. Start a ride to see history here.',
            icon: Icons.history,
          );
        }
        final sessions = provider.sessions;
        final allTimeTrips = sessions.length;
        final allTimeRides = sessions.fold<int>(
          0,
          (sum, s) => sum + _demoRidesCollected(s),
        );
        return RefreshIndicator(
          onRefresh: () => provider.loadSessions(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AllTimeStatsCard(
                  totalTrips: allTimeTrips,
                  totalRides: allTimeRides,
                ),
                const SizedBox(height: 24),
                Text(
                  'Trip history',
                  style: AppTextStyles.headlineMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...sessions.map((s) => _HistoryTile(
                      session: s,
                      formatDate: _formatDate,
                      demoRides: _demoRidesCollected(s),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AllTimeStatsCard extends StatelessWidget {
  const _AllTimeStatsCard({
    required this.totalTrips,
    required this.totalRides,
  });

  final int totalTrips;
  final int totalRides;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primaryLight.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.insights_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'All-time stats',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$totalTrips',
                      style: AppTextStyles.headlineMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total trips',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$totalRides',
                      style: AppTextStyles.headlineMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rides collected',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.session,
    required this.formatDate,
    required this.demoRides,
  });

  final DriverSession session;
  final String Function(DateTime) formatDate;
  final int demoRides;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          child: Icon(Icons.directions_bus_rounded, color: AppColors.primary),
        ),
        title: Text(
          session.routeDisplayName,
          style: AppTextStyles.bodyLarge,
        ),
        subtitle: Text(
          '${formatDate(session.startedAt)} · $demoRides rides',
          style: AppTextStyles.bodySmall,
        ),
      ),
    );
  }
}
