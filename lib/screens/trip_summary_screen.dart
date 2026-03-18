import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/constants/route_names.dart';
import '../models/driver_session.dart';

class TripSummaryScreen extends StatelessWidget {
  const TripSummaryScreen({super.key, required this.session});

  final DriverSession session;

  /// Demo: same pseudo-random as active ride screen (stable per session).
  static int _demoRidesCollected(DriverSession s) {
    final hash = s.sessionId.hashCode.abs();
    return (hash % 11) + 3;
  }

  String _formatDateTime(DateTime d) {
    return '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip summary'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.routeDisplayName,
                      style: AppTextStyles.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Started: ${_formatDateTime(session.startedAt)}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (session.endedAt != null)
                      Text(
                        'Ended: ${_formatDateTime(session.endedAt!)}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Rides collected',
                            style: AppTextStyles.bodyLarge,
                          ),
                          Text(
                            '${_demoRidesCollected(session)}',
                            style: AppTextStyles.headlineMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                RouteNames.home,
                (route) => false,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
