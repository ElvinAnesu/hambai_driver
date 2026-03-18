import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/mock_auth_service.dart';

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

  Future<void> sendOtp(String phone) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _auth.sendOtp(phone);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifyOtp(String otp) async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _auth.verifyOtp(otp);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({String? fullName, String? avatarUrl}) async {
    await _auth.updateProfile(fullName: fullName, avatarUrl: avatarUrl);
    _user = await _auth.loadUser();
    notifyListeners();
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
