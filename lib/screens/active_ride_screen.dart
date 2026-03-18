import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/constants/route_names.dart';
import '../models/driver_session.dart';
import '../models/location.dart';
import '../providers/driver_session_provider.dart';
import 'trip_summary_screen.dart';

/// Demo: stable pseudo-random rides count (simulates automatic updates from QR/code scans).
int _demoRidesCollected(DriverSession session) {
  final hash = session.sessionId.hashCode.abs();
  return (hash % 11) + 3; // 3–13
}

class ActiveRideScreen extends StatelessWidget {
  const ActiveRideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DriverSessionProvider>(
      builder: (context, provider, _) {
        final session = provider.activeSession;
        if (session == null || !session.isActive) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.of(context).popUntil(
                  (route) => route.settings.name == RouteNames.home);
            }
          });
          return const Scaffold(
            body: Center(child: Text('No active ride')),
          );
        }
        return _ActiveRideContent(session: session);
      },
    );
  }
}

class _ActiveRideContent extends StatelessWidget {
  const _ActiveRideContent({required this.session});

  final DriverSession session;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(session.routeDisplayName),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () =>
                Navigator.of(context).pushNamed(RouteNames.driverCodeDisplay),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.primaryLight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Now at: ${session.currentStop?.name ?? "—"}',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_demoRidesCollected(session)} rides collected',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: session.stops.length,
              itemBuilder: (context, i) {
                final stop = session.stops[i];
                final isCurrent = i == session.currentStopIndex;
                final isPast = i < session.currentStopIndex;
                final passengersAlighting = session.passengersAlightingAt(i);
                final hasArrived = session.hasArrivedAtStop(i);
                final arrivedAt = session.arrivedAt(i);
                return _StopTile(
                  stop: stop,
                  index: i + 1,
                  isCurrent: isCurrent,
                  isPast: isPast,
                  passengersAlighting: passengersAlighting,
                  hasArrived: hasArrived,
                  arrivedAt: arrivedAt,
                  onMarkArrived: () => context.read<DriverSessionProvider>().markArrivedAtStop(i),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _showEndRideConfirm(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('End ride'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEndRideConfirm(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End ride?'),
        content: const Text(
          'This will end the current session. You can view the summary after.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ended = await context
                  .read<DriverSessionProvider>()
                  .endSession();
              if (!context.mounted) return;
              Navigator.of(context).popUntil(
                  (route) => route.settings.name == RouteNames.home);
              if (ended != null) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (c) => TripSummaryScreen(session: ended),
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('End ride'),
          ),
        ],
      ),
    );
  }
}

class _StopTile extends StatelessWidget {
  const _StopTile({
    required this.stop,
    required this.index,
    required this.isCurrent,
    required this.isPast,
    required this.passengersAlighting,
    required this.hasArrived,
    required this.arrivedAt,
    required this.onMarkArrived,
  });

  final Location stop;
  final int index;
  final bool isCurrent;
  final bool isPast;
  final int passengersAlighting;
  final bool hasArrived;
  final DateTime? arrivedAt;
  final VoidCallback onMarkArrived;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppColors.primary
                      : isPast
                          ? AppColors.textSecondary
                          : AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isPast
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : Text(
                          '$index',
                          style: TextStyle(
                            fontSize: 12,
                            color: isCurrent
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                ),
              ),
              if (index < 10)
                Container(
                  width: 2,
                  height: 24,
                  color: AppColors.surface,
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Card(
              color: isCurrent ? AppColors.primaryLight : null,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stop.name,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight:
                            isCurrent ? FontWeight.w600 : FontWeight.normal,
                        color: isCurrent
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (stop.address != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        stop.address!,
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                    if (passengersAlighting > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$passengersAlighting passenger${passengersAlighting == 1 ? '' : 's'} getting off here',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    if (hasArrived && arrivedAt != null)
                      Text(
                        'Arrived at ${arrivedAt!.hour.toString().padLeft(2, '0')}:${arrivedAt!.minute.toString().padLeft(2, '0')}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: onMarkArrived,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                          ),
                          child: const Text('Mark arrived'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
