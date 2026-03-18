import 'location.dart';

/// Active or past driver session (route, code, stops, rides collected).
/// [arrivedAtStop] = stop index -> time driver marked arrived at that pickup/drop point.
/// [passengerDropOffsByStop] = stop index -> number of passengers alighting (drop-off) at that stop.
class DriverSession {
  final String sessionId;
  final String routeId;
  final String routeDisplayName;
  final List<Location> stops;
  final String driverCode;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int currentStopIndex;
  final int ridesCollected;
  final Map<int, DateTime> arrivedAtStop;
  final Map<int, int> passengerDropOffsByStop;

  const DriverSession({
    required this.sessionId,
    required this.routeId,
    required this.routeDisplayName,
    required this.stops,
    required this.driverCode,
    required this.startedAt,
    this.endedAt,
    this.currentStopIndex = 0,
    this.ridesCollected = 0,
    this.arrivedAtStop = const {},
    this.passengerDropOffsByStop = const {},
  });

  bool get isActive => endedAt == null;
  Location? get currentStop =>
      stops.isNotEmpty && currentStopIndex < stops.length
          ? stops[currentStopIndex]
          : null;

  bool hasArrivedAtStop(int index) => arrivedAtStop.containsKey(index);
  DateTime? arrivedAt(int index) => arrivedAtStop[index];
  int passengersAlightingAt(int index) =>
      passengerDropOffsByStop[index] ?? 0;

  DriverSession copyWith({
    String? sessionId,
    String? routeId,
    String? routeDisplayName,
    List<Location>? stops,
    String? driverCode,
    DateTime? startedAt,
    DateTime? endedAt,
    int? currentStopIndex,
    int? ridesCollected,
    Map<int, DateTime>? arrivedAtStop,
    Map<int, int>? passengerDropOffsByStop,
  }) {
    return DriverSession(
      sessionId: sessionId ?? this.sessionId,
      routeId: routeId ?? this.routeId,
      routeDisplayName: routeDisplayName ?? this.routeDisplayName,
      stops: stops ?? this.stops,
      driverCode: driverCode ?? this.driverCode,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      currentStopIndex: currentStopIndex ?? this.currentStopIndex,
      ridesCollected: ridesCollected ?? this.ridesCollected,
      arrivedAtStop: arrivedAtStop ?? this.arrivedAtStop,
      passengerDropOffsByStop:
          passengerDropOffsByStop ?? this.passengerDropOffsByStop,
    );
  }

  Map<String, dynamic> toJson() {
    final arrivedMap = <String, String>{};
    for (final e in arrivedAtStop.entries) {
      arrivedMap[e.key.toString()] = e.value.toIso8601String();
    }
    final dropOffMap = <String, int>{};
    for (final e in passengerDropOffsByStop.entries) {
      dropOffMap[e.key.toString()] = e.value;
    }
    return {
      'sessionId': sessionId,
      'routeId': routeId,
      'routeDisplayName': routeDisplayName,
      'stops': stops.map((s) => s.toJson()).toList(),
      'driverCode': driverCode,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'currentStopIndex': currentStopIndex,
      'ridesCollected': ridesCollected,
      'arrivedAtStop': arrivedMap,
      'passengerDropOffsByStop': dropOffMap,
    };
  }

  factory DriverSession.fromJson(Map<String, dynamic> json) {
    final stopsList = json['stops'] as List<dynamic>?;
    final stops = stopsList
            ?.map((e) => Location.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final arrivedRaw = json['arrivedAtStop'] as Map<String, dynamic>?;
    final arrivedAtStop = <int, DateTime>{};
    if (arrivedRaw != null) {
      for (final e in arrivedRaw.entries) {
        final k = int.tryParse(e.key);
        if (k != null && e.value is String) {
          arrivedAtStop[k] = DateTime.parse(e.value as String);
        }
      }
    }
    final dropOffRaw = json['passengerDropOffsByStop'] as Map<String, dynamic>?;
    final passengerDropOffsByStop = <int, int>{};
    if (dropOffRaw != null) {
      for (final e in dropOffRaw.entries) {
        final k = int.tryParse(e.key);
        final v = e.value;
        if (k != null && v != null) {
          passengerDropOffsByStop[k] = v is int ? v : (v is num ? v.toInt() : 0);
        }
      }
    }
    return DriverSession(
      sessionId: json['sessionId'] as String,
      routeId: json['routeId'] as String,
      routeDisplayName: json['routeDisplayName'] as String,
      stops: stops,
      driverCode: json['driverCode'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
      currentStopIndex: json['currentStopIndex'] as int? ?? 0,
      ridesCollected: json['ridesCollected'] as int? ?? 0,
      arrivedAtStop: arrivedAtStop,
      passengerDropOffsByStop: passengerDropOffsByStop,
    );
  }
}
