import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How to use Hambai Driver',
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(
              '1. Start a ride: Tap "Start ride", choose your route and confirm. '
              'Your driver code and QR will be shown.\n\n'
              '2. Show your code: Passengers can enter the code or scan the QR to board.\n\n'
              '3. Advance stops: On the active ride screen, tap "Next stop" when you reach each stop.\n\n'
              '4. End ride: When finished, tap "End ride" and confirm. View your trip summary and history in the History tab.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
