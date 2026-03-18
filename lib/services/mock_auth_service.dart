import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/formatters.dart';

/// Mock auth: OTP is any 6 digits; data stored in SharedPreferences.
class MockAuthService {
  static const _keyOnboardingComplete = 'driver_onboarding_complete';
  static const _keyUser = 'driver_user';
  static const _keyPendingPhone = 'driver_pending_phone';

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingComplete, true);
  }

  Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingComplete) ?? false;
  }

  Future<User?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyUser);
    if (json == null) return null;
    try {
      return User.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Mock: always succeeds after short delay; stores pending phone for OTP.
  Future<void> sendOtp(String phone) async {
    final normalized = Formatters.normalizePhone(phone);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPendingPhone, normalized);
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  /// Mock: any 6-digit OTP succeeds; creates/updates user and clears pending.
  Future<User> verifyOtp(String otp) async {
    if (otp.length != AppConstants.otpLength) {
      throw Exception('Invalid OTP');
    }
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString(_keyPendingPhone) ?? '263712345678';
    await prefs.remove(_keyPendingPhone);
    final user = User(
      id: 'driver_${phone}_${DateTime.now().millisecondsSinceEpoch}',
      phone: Formatters.displayPhone(phone),
      fullName: null,
      avatarUrl: null,
    );
    await _saveUser(user);
    return user;
  }

  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  Future<void> updateProfile({String? fullName, String? avatarUrl}) async {
    final current = await loadUser();
    if (current == null) return;
    final updated = current.copyWith(
      fullName: fullName ?? current.fullName,
      avatarUrl: avatarUrl ?? current.avatarUrl,
    );
    await _saveUser(updated);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
    await prefs.remove(_keyPendingPhone);
  }

  Future<void> deleteAccount() async {
    await logout();
  }
}
