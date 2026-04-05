import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/driver_session.dart';
import '../models/location.dart';

/// Mock driver history: past sessions stored in SharedPreferences + seed data.
class MockDriverHistoryService {
  static const _keySessions = 'driver_history_sessions';
  static const _keySeedDone = 'driver_history_seed_done';

  static List<DriverSession> _seedSessions() {
    final now = DateTime.now();
    final stops1 = [
      const Location(id: 's1', name: 'Harare CBD', address: 'Corner of Jason Moyo & First St'),
      const Location(id: 's2', name: 'Avondale Shops', address: 'Avondale Shopping Centre'),
      const Location(id: 's3', name: 'Borrowdale', address: 'Borrowdale Village'),
    ];
    final stops2 = [
      const Location(id: 's4', name: 'Mbare Musika', address: 'Mbare Bus Terminus'),
      const Location(id: 's5', name: 'Harare CBD', address: 'Fourth Street'),
      const Location(id: 's6', name: 'Highlands Shops', address: 'Highlands Shopping Centre'),
    ];
    final stops3 = [
      const Location(id: 's7', name: 'Epworth', address: 'Epworth Centre'),
      const Location(id: 's8', name: 'Harare CBD', address: 'Robert Mugabe Rd'),
    ];
    return [
      DriverSession(
        sessionId: 'seed_1',
        tripId: 'seed_1',
        routeId: 'route_1',
        routeDisplayName: 'Harare CBD – Avondale',
        stops: stops1,
        driverCode: 'A1B2C3',
        startedAt: now.subtract(const Duration(days: 5)),
        endedAt: now.subtract(const Duration(days: 5)).add(const Duration(hours: 2)),
        currentStopIndex: 3,
        ridesCollected: 12,
      ),
      DriverSession(
        sessionId: 'seed_2',
        tripId: 'seed_2',
        routeId: 'route_2',
        routeDisplayName: 'Mbare – CBD – Highlands',
        stops: stops2,
        driverCode: 'X9Y8Z7',
        startedAt: now.subtract(const Duration(days: 3)),
        endedAt: now.subtract(const Duration(days: 3)).add(const Duration(hours: 1, minutes: 30)),
        currentStopIndex: 3,
        ridesCollected: 8,
      ),
      DriverSession(
        sessionId: 'seed_3',
        tripId: 'seed_3',
        routeId: 'route_1',
        routeDisplayName: 'Harare CBD – Avondale',
        stops: stops1,
        driverCode: 'K4L5M6',
        startedAt: now.subtract(const Duration(days: 2)),
        endedAt: now.subtract(const Duration(days: 2)).add(const Duration(hours: 2)),
        currentStopIndex: 3,
        ridesCollected: 5,
      ),
      DriverSession(
        sessionId: 'seed_4',
        tripId: 'seed_4',
        routeId: 'route_3',
        routeDisplayName: 'Epworth – CBD',
        stops: stops3,
        driverCode: 'P7Q8R9',
        startedAt: now.subtract(const Duration(days: 1)),
        endedAt: now.subtract(const Duration(days: 1)).add(const Duration(hours: 1)),
        currentStopIndex: 2,
        ridesCollected: 6,
      ),
      DriverSession(
        sessionId: 'seed_5',
        tripId: 'seed_5',
        routeId: 'route_2',
        routeDisplayName: 'Mbare – CBD – Highlands',
        stops: stops2,
        driverCode: 'S1T2U3',
        startedAt: now.subtract(const Duration(hours: 8)),
        endedAt: now.subtract(const Duration(hours: 6)),
        currentStopIndex: 3,
        ridesCollected: 9,
      ),
    ];
  }

  Future<List<DriverSession>> getPastSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_keySessions);
    final list = <DriverSession>[];

    final seedDone = prefs.getBool(_keySeedDone) ?? false;
    if (!seedDone) {
      list.addAll(_seedSessions());
      await prefs.setBool(_keySeedDone, true);
    }

    if (jsonList != null) {
      for (final s in jsonList) {
        try {
          list.add(DriverSession.fromJson(
              jsonDecode(s) as Map<String, dynamic>));
        } catch (_) {
          // skip invalid
        }
      }
    }
    list.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return list;
  }

  Future<void> saveSession(DriverSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keySessions) ?? [];
    list.add(jsonEncode(session.toJson()));
    await prefs.setStringList(_keySessions, list);
  }
}
