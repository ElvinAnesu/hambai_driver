import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../providers/driver_session_provider.dart';

class DriverCodeDisplayScreen extends StatelessWidget {
  const DriverCodeDisplayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DriverSessionProvider>(
      builder: (context, provider, _) {
        final session = provider.activeSession;
        if (session == null || !session.isActive) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Driver code'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            body: const Center(
              child: Text('No active session. Start a ride first.'),
            ),
          );
        }
        return _CodeContent(code: session.driverCode, sessionId: session.sessionId);
      },
    );
  }
}

class _CodeContent extends StatelessWidget {
  const _CodeContent({
    required this.code,
    required this.sessionId,
  });

  final String code;
  final String sessionId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver code'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text(
              'Passengers can enter this code or scan the QR',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    code,
                    style: AppTextStyles.headlineLarge.copyWith(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: 8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            QrImageView(
              data: sessionId,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppColors.primary,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
