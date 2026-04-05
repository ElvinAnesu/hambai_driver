import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  AuthProvider({MockAuthService? authService})
      : _auth = authService ?? MockAuthService();

  final MockAuthService _auth;
  User? _user;
  bool _hasCompletedOnboarding = false;
  bool _isLoading = false;
  bool _isInitialized = false;

  User? get currentUser => _user;
  bool get isAuthenticated => _user != null;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isLoading = true;
    notifyListeners();
    try {
      _hasCompletedOnboarding = await _auth.hasCompletedOnboarding();
      _user = await _auth.loadUser();
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> completeOnboarding() async {
    await _auth.completeOnboarding();
    _hasCompletedOnboarding = true;
    notifyListeners();
  }

  Future<void> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _auth.loginWithEmailPassword(
        email: email,
        password: password,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @Deprecated('OTP flow removed. Use loginWithEmailPassword instead.')
  Future<void> sendOtp(String phone) async {
    throw UnimplementedError('OTP flow removed');
  }

  @Deprecated('OTP flow removed. Use loginWithEmailPassword instead.')
  Future<void> verifyOtp(String otp) async {
    throw UnimplementedError('OTP flow removed');
  }

  Future<void> updateProfile({String? fullName, String? avatarUrl}) async {
    await _auth.updateProfile(fullName: fullName, avatarUrl: avatarUrl);
    _user = await _auth.loadUser();
    notifyListeners();
  }

  Future<void> uploadAvatar({
    required Uint8List bytes,
    required String fileExtension,
    required String contentType,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _auth.uploadAvatar(
        bytes: bytes,
        fileExtension: fileExtension,
        contentType: contentType,
      );
      _user = await _auth.loadUser();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _auth.logout();
    _user = null;
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    await _auth.deleteAccount();
    _user = null;
    notifyListeners();
  }
}
