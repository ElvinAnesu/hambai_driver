import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/constants/route_names.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/validators.dart';
import '../core/utils/formatters.dart';
import '../providers/auth_provider.dart';
import '../core/widgets/loading_indicator.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _controllers = List.generate(
    AppConstants.otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    AppConstants.otpLength,
    (_) => FocusNode(),
  );
  String? _error;

  String get _displayPhone {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) return Formatters.displayPhone(args);
    return AppConstants.countryCode;
  }

  String get _otpText =>
      _controllers.map((c) => c.text).join();

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _onOtpChanged(int index, String value) {
    if (value.length == 1) {
      if (index < AppConstants.otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      }
      setState(() => _error = null);
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _verify() async {
    _error = null;
    final otp = _otpText;
    final err = Validators.otp(otp.isEmpty ? null : otp,
        length: AppConstants.otpLength);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    try {
      await context.read<AuthProvider>().verifyOtp(otp);
    } catch (e) {
      setState(() => _error = 'Verification failed. Try again.');
      return;
    }
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (auth.currentUser?.fullName == null ||
        auth.currentUser!.fullName!.trim().isEmpty) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        RouteNames.completeProfile,
        (route) => false,
      );
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil(
        RouteNames.home,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify OTP'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    'We sent a code to $_displayPhone',
                    style: AppTextStyles.bodyLarge,
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(AppConstants.otpLength, (index) {
                      return SizedBox(
                        width: 44,
                        child: TextFormField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: AppTextStyles.headlineMedium,
                          decoration: InputDecoration(
                            counterText: '',
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: AppColors.surfaceBright,
                          ),
                          onChanged: (value) => _onOtpChanged(index, value),
                        ),
                      );
                    }),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      if (auth.isLoading) {
                        return const LoadingIndicator();
                      }
                      return FilledButton(
                        onPressed: _verify,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Verify'),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
