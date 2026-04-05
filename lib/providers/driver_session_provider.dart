import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/driver_session.dart';
import '../models/location.dart';
import '../models/predefined_route.dart';
import '../services/mock_driver_history_service.dart';
import '../services/trip_service.dart';

class DriverSessionProvider with ChangeNotifier {
  DriverSessionProvider({MockDriverHistoryService? historyService})
      : _historyService = historyService ?? MockDriverHistoryService();

  final MockDriverHistoryService _historyService;
  final TripService _tripService = TripService();
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

  Future<StartTripResult> startSession({
    required PredefinedRoute route,
    required String profileId,
    required String direction,
  }) async {
    final result = await _tripService.startTrip(
      profileId: profileId,
      routeId: route.id,
      direction: direction,
    );
    if (!result.ok) {
      return result;
    }

    final stops = List<Location>.from(route.stops);
    final passengerDropOffsByStop = _mockPassengerDropOffs(stops.length);
    _activeSession = DriverSession(
      sessionId: result.tripId!,
      tripId: result.tripId!,
      routeId: route.id,
      routeDisplayName: route.displayName,
      stops: stops,
      driverCode: (result.driverCode ?? '').trim().isEmpty
          ? _generateDriverCode()
          : result.driverCode!,
      startedAt: DateTime.now(),
      currentStopIndex: 0,
      ridesCollected: 0,
      passengerDropOffsByStop: passengerDropOffsByStop,
    );
    notifyListeners();
    return result;
  }

  Future<void> markArrivedAtStop(int stopIndex) async {
    if (_activeSession == null || !_activeSession!.isActive) return;
    if (stopIndex < 0 || stopIndex >= _activeSession!.stops.length) return;
    final current = _activeSession!;
    if (stopIndex != current.currentStopIndex) return;
    final updated = Map<int, DateTime>.from(current.arrivedAtStop)
      ..[stopIndex] = DateTime.now();
    var nextStopIndex = current.currentStopIndex;
    if (stopIndex == current.currentStopIndex &&
        current.currentStopIndex + 1 < current.stops.length) {
      nextStopIndex = current.currentStopIndex + 1;
    }

    _activeSession = current.copyWith(
      arrivedAtStop: updated,
      currentStopIndex: nextStopIndex,
    );
    await _tripService.updateCurrentStopIndex(
      tripId: current.tripId,
      currentStopIndex: nextStopIndex,
    );
    notifyListeners();
  }

  Future<void> advanceStop() async {
    if (_activeSession == null || !_activeSession!.isActive) return;
    final stops = _activeSession!.stops;
    final next = _activeSession!.currentStopIndex + 1;
    if (next >= stops.length) return;
    final current = _activeSession!;
    _activeSession = current.copyWith(currentStopIndex: next);
    await _tripService.updateCurrentStopIndex(
      tripId: current.tripId,
      currentStopIndex: next,
    );
    notifyListeners();
  }

  /// Clears the in-memory active session (e.g. after refresh shows no active trip on the server).
  void clearActiveSession() {
    if (_activeSession == null) return;
    _activeSession = null;
    notifyListeners();
  }

  void syncActiveSessionFromRealtime(DriverSession session) {
    final current = _activeSession;
    if (current == null || !current.isActive) {
      _activeSession = session;
      notifyListeners();
      return;
    }

    if (current.tripId != session.tripId) {
      _activeSession = session;
      notifyListeners();
      return;
    }

    final needsUpdate = current.currentStopIndex != session.currentStopIndex ||
        current.routeDisplayName != session.routeDisplayName ||
        current.routeId != session.routeId ||
        current.stops.length != session.stops.length;
    if (!needsUpdate) return;

    _activeSession = current.copyWith(
      currentStopIndex: session.currentStopIndex,
      routeId: session.routeId,
      routeDisplayName: session.routeDisplayName,
      stops: session.stops,
      startedAt: session.startedAt,
      driverCode: session.driverCode,
    );
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
    return completeSession(cancelled: false);
  }

  Future<DriverSession?> cancelSession() async {
    return completeSession(cancelled: true);
  }

  Future<DriverSession?> completeSession({required bool cancelled}) async {
    if (_activeSession == null) return null;
    final ended = _activeSession!.copyWith(endedAt: DateTime.now());
    await _tripService.completeTrip(
      tripId: ended.tripId,
      status: cancelled ? 'cancelled' : 'ended',
    );
    await _historyService.saveSession(ended);
    _activeSession = null;
    notifyListeners();
    return ended;
  }
}
