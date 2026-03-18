import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/mock_settings_service.dart';

class SettingsProvider with ChangeNotifier {
  SettingsProvider({MockSettingsService? service})
      : _service = service ?? MockSettingsService();

  final MockSettingsService _service;
  ThemeMode _themeMode = ThemeMode.system;
  bool _notificationsEnabled = true;
  bool _initialized = false;

  ThemeMode get themeMode => _themeMode;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;
    final mode = await _service.getThemeMode();
    _themeMode = switch (mode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    _notificationsEnabled = await _service.getNotificationsEnabled();
    _initialized = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _service.setThemeMode(value);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await _service.setNotificationsEnabled(value);
    notifyListeners();
  }
}
