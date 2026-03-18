import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of service'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hambai Driver – Terms of service',
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'By using the Hambai Driver app you agree to these terms. '
              'You are responsible for operating your vehicle safely and in line with local laws. '
              'Ride data is recorded for the purpose of the service. '
              'We may update these terms from time to time.',
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
