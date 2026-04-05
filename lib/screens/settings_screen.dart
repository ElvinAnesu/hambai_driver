import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../core/theme/app_colors.dart';
import '../core/widgets/app_bar_refresh_button.dart';
import '../core/theme/app_text_styles.dart';
import '../core/constants/route_names.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _driverCode;
  bool _isCodeLoading = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadDriverCode();
  }

  Future<void> _loadDriverCode() async {
    final profileId = sb.Supabase.instance.client.auth.currentUser?.id;
    if (profileId == null || profileId.isEmpty) {
      setState(() {
        _driverCode = null;
        _isCodeLoading = false;
      });
      return;
    }

    try {
      final row = await sb.Supabase.instance.client
          .from('drivers')
          .select('driver_code')
          .eq('profile_id', profileId)
          .maybeSingle();
      final code = (row?['driver_code'] as String?)?.trim();
      if (!mounted) return;
      setState(() {
        _driverCode = (code == null || code.isEmpty) ? null : code;
        _isCodeLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _driverCode = null;
        _isCodeLoading = false;
      });
    }
  }

  Future<void> _exportDriverCodeQr() async {
    if (_isExporting || _driverCode == null || _driverCode!.isEmpty) {
      return;
    }
    setState(() {
      _isExporting = true;
    });
    try {
      final pngBytes = await _buildDriverQrPng(_driverCode!);
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/driver_code_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes, flush: true);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Scan this QR code or use code ${_driverCode!} to pay.',
        subject: 'Driver payment code',
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to export driver QR code')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<List<int>> _buildDriverQrPng(String driverCode) async {
    final painter = QrPainter(
      data: driverCode,
      version: QrVersions.auto,
      gapless: true,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Color(0xFF0F172A),
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Color(0xFF0F172A),
      ),
      emptyColor: Colors.white,
    );

    final qrData = await painter.toImageData(
      220,
      format: ui.ImageByteFormat.png,
    );
    if (qrData == null) {
      throw Exception('Failed to generate QR image');
    }
    final qrCodec = await ui.instantiateImageCodec(qrData.buffer.asUint8List());
    final qrFrame = await qrCodec.getNextFrame();
    final qrImage = qrFrame.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const width = 280.0;
    const height = 320.0;
    const qrSize = 220.0;
    const qrLeft = (width - qrSize) / 2;
    const qrTop = 24.0;

    canvas.drawRect(
      const Rect.fromLTWH(0, 0, width, height),
      Paint()..color = Colors.white,
    );
    canvas.drawImageRect(
      qrImage,
      Rect.fromLTWH(0, 0, qrImage.width.toDouble(), qrImage.height.toDouble()),
      const Rect.fromLTWH(qrLeft, qrTop, qrSize, qrSize),
      Paint(),
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: driverCode,
        style: AppTextStyles.headlineMedium.copyWith(
          color: const Color(0xFF0F172A),
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: width - 24);
    textPainter.paint(
      canvas,
      Offset((width - textPainter.width) / 2, qrTop + qrSize + 20),
    );

    final composed = await recorder.endRecording().toImage(
      width.toInt(),
      height.toInt(),
    );
    final byteData = await composed.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
      throw Exception('Failed to encode QR export image');
      }
    return byteData.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final hasDriverCode = _driverCode != null && _driverCode!.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Options'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: const [AppBarRefreshButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.12),
                  AppColors.primaryLight.withValues(alpha: 0.45),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Manage your app preferences and account actions in one place.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: AppColors.textSecondary.withValues(alpha: 0.15),
              ),
            ),
            child: ListTile(
              leading: const Icon(Icons.qr_code_2_rounded),
              title: const Text('Export driver code QR'),
              subtitle: _isCodeLoading
                  ? const Text('Loading driver code...')
                  : Text(
                      hasDriverCode
                          ? 'Share QR image and code with passengers'
                          : 'No driver code found',
                    ),
              trailing: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.ios_share_rounded),
              onTap: (_isCodeLoading || !hasDriverCode || _isExporting)
                  ? null
                  : _exportDriverCodeQr,
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: AppColors.textSecondary.withValues(alpha: 0.15),
              ),
            ),
            child: Consumer<SettingsProvider>(
              builder: (context, settings, _) {
                return ListTile(
                  leading: const Icon(Icons.palette_outlined),
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
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: AppColors.textSecondary.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.logout_rounded),
                  title: Text(
                    'Log out',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  onTap: () => _logout(context),
                ),
                Divider(height: 1, color: AppColors.textSecondary.withValues(alpha: 0.15)),
                ListTile(
                  leading: const Icon(Icons.delete_forever_outlined, color: AppColors.error),
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
