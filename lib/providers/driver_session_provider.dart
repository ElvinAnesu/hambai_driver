import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/driver_session.dart';
import '../models/location.dart';
import '../models/predefined_route.dart';
import '../services/mock_driver_history_service.dart';

class DriverSessionProvider with ChangeNotifier {
  DriverSessionProvider({MockDriverHistoryService? historyService})
      : _historyService = historyService ?? MockDriverHistoryService();

  final MockDriverHistoryService _historyService;
  DriverSession? _activeSession;

  DriverSession? get activeSession => _activeSession;
  bool get hasActiveSession => _activeSession != null && _activeSession!.isActive;

  static String _generateDriverCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random();
    return List.generate(6, (_) => chars[r.nextInt(chars.length)]).join();
  }

  /// Mock: passengers have selected drop-off points (stops where they alight).
  static Map<int, int> _mockPassengerDropOffs(int stopCount) {
    final r = Random();
    final map = <int, int>{};
    if (stopCount <= 1) return map;
    for (var i = 1; i < stopCount; i++) {
      final count = r.nextInt(3) + 1;
      map[i] = count;
    }
    return map;
  }

  void startSession(PredefinedRoute route) {
    final stops = List<Location>.from(route.stops);
    final passengerDropOffsByStop = _mockPassengerDropOffs(stops.length);
    _activeSession = DriverSession(
      sessionId: 'session_${DateTime.now().millisecondsSinceEpoch}',
      routeId: route.id,
      routeDisplayName: route.displayName,
      stops: stops,
      driverCode: _generateDriverCode(),
      startedAt: DateTime.now(),
      currentStopIndex: 0,
      ridesCollected: 0,
      passengerDropOffsByStop: passengerDropOffsByStop,
    );
    notifyListeners();
  }

  void markArrivedAtStop(int stopIndex) {
    if (_activeSession == null || !_activeSession!.isActive) return;
    if (stopIndex < 0 || stopIndex >= _activeSession!.stops.length) return;
    final updated = Map<int, DateTime>.from(_activeSession!.arrivedAtStop)
      ..[stopIndex] = DateTime.now();
    _activeSession = _activeSession!.copyWith(arrivedAtStop: updated);
    notifyListeners();
  }

  void advanceStop() {
    if (_activeSession == null || !_activeSession!.isActive) return;
    final stops = _activeSession!.stops;
    final next = _activeSession!.currentStopIndex + 1;
    if (next >= stops.length) return;
    _activeSession = _activeSession!.copyWith(currentStopIndex: next);
    notifyListeners();
  }

  void addRideCollected() {
    if (_activeSession == null || !_activeSession!.isActive) return;
    _activeSession = _activeSession!.copyWith(
      ridesCollected: _activeSession!.ridesCollected + 1,
    );
    notifyListeners();
  }

  Future<DriverSession?> endSession() async {
    if (_activeSession == null) return null;
    final ended = _activeSession!.copyWith(endedAt: DateTime.now());
    await _historyService.saveSession(ended);
    _activeSession = null;
    notifyListeners();
    return ended;
  }
}
