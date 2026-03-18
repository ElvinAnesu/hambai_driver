import 'package:flutter/foundation.dart';
import '../models/driver_session.dart';
import '../services/mock_driver_history_service.dart';

class DriverHistoryProvider with ChangeNotifier {
  DriverHistoryProvider({MockDriverHistoryService? service})
      : _service = service ?? MockDriverHistoryService();

  final MockDriverHistoryService _service;
  List<DriverSession> _sessions = [];
  bool _isLoading = false;

  List<DriverSession> get sessions => List.unmodifiable(_sessions);
  bool get isLoading => _isLoading;

  Future<void> loadSessions() async {
    _isLoading = true;
    notifyListeners();
    try {
      _sessions = await _service.getPastSessions();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
