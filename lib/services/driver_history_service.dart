import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../models/driver_session.dart';

class DriverHistoryService {
  Future<List<DriverSession>> getPastSessions() async {
    final client = sb.Supabase.instance.client;
    final profileId = client.auth.currentUser?.id;
    if (profileId == null || profileId.isEmpty) {
      return const <DriverSession>[];
    }

    final driverRow = await client
        .from('drivers')
        .select('id, driver_code')
        .eq('profile_id', profileId)
        .maybeSingle();
    if (driverRow == null) {
      return const <DriverSession>[];
    }

    final driverId = driverRow['id'] as String?;
    if (driverId == null || driverId.isEmpty) {
      return const <DriverSession>[];
    }

    final driverCode = (driverRow['driver_code'] as String?) ?? '';

    final tripsResponse = await client
        .from('trips')
        .select('id, route_id, started_at, ended_at, current_stop_index, routes(display_name)')
        .eq('driver_id', driverId)
        .not('ended_at', 'is', null)
        .order('started_at', ascending: false);

    final trips = (tripsResponse as List<dynamic>).cast<Map<String, dynamic>>();
    if (trips.isEmpty) {
      return const <DriverSession>[];
    }

    final tripIds = trips
        .map((row) => row['id'] as String?)
        .whereType<String>()
        .toList();

    final ridesCountByTrip = <String, int>{};
    if (tripIds.isNotEmpty) {
      final ridesResponse = await client
          .from('rides')
          .select('trip_id')
          .inFilter('trip_id', tripIds)
          .eq('status', 'success');
      for (final row in (ridesResponse as List<dynamic>).cast<Map<String, dynamic>>()) {
        final tripId = row['trip_id'] as String?;
        if (tripId == null) continue;
        ridesCountByTrip[tripId] = (ridesCountByTrip[tripId] ?? 0) + 1;
      }
    }

    return trips.map((row) {
      final tripId = row['id'] as String? ?? '';
      final routeId = row['route_id'] as String? ?? '';
      final startedAt = _parseDateTime(row['started_at']) ?? DateTime.now();
      final endedAt = _parseDateTime(row['ended_at']);
      final currentStopIndex = row['current_stop_index'] is int
          ? row['current_stop_index'] as int
          : ((row['current_stop_index'] as num?)?.toInt() ?? 0);
      final routeDisplayName = _extractRouteDisplayName(row['routes']) ?? routeId;

      return DriverSession(
        sessionId: tripId,
        tripId: tripId,
        routeId: routeId,
        routeDisplayName: routeDisplayName,
        stops: const [],
        driverCode: driverCode,
        startedAt: startedAt,
        endedAt: endedAt,
        currentStopIndex: currentStopIndex,
        ridesCollected: ridesCountByTrip[tripId] ?? 0,
      );
    }).toList();
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  String? _extractRouteDisplayName(dynamic routesValue) {
    if (routesValue is Map<String, dynamic>) {
      return routesValue['display_name'] as String?;
    }
    if (routesValue is List && routesValue.isNotEmpty) {
      final first = routesValue.first;
      if (first is Map<String, dynamic>) {
        return first['display_name'] as String?;
      }
    }
    return null;
  }
}
