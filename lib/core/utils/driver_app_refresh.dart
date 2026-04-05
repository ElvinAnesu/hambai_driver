import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/driver_session.dart';
import '../../models/location.dart';
import '../../models/predefined_route.dart';
import '../../providers/auth_provider.dart';
import '../../providers/driver_history_provider.dart';
import '../../providers/driver_session_provider.dart';
import '../../services/route_service.dart';
import '../../services/trip_service.dart';

/// Builds [DriverSession] from a Supabase `trips` row and optional assigned route (same idea as home dashboard).
DriverSession driverSessionFromActiveTripRow(
  Map<String, dynamic> row,
  PredefinedRoute? route,
) {
  final startedAtRaw = row['started_at'] as String?;
  final startedAt = startedAtRaw == null
      ? DateTime.now()
      : DateTime.tryParse(startedAtRaw) ?? DateTime.now();
  final currentStopIndex = row['current_stop_index'] is int
      ? row['current_stop_index'] as int
      : int.tryParse('${row['current_stop_index']}') ?? 0;
  final routeId = row['route_id'] as String? ?? route?.id ?? '';
  final tripId = row['id'] as String? ?? 'active_trip';
  return DriverSession(
    sessionId: tripId,
    tripId: tripId,
    routeId: routeId,
    routeDisplayName: route?.displayName ?? 'Active trip',
    stops: route?.stops ?? const <Location>[],
    driverCode: '—',
    startedAt: startedAt,
    currentStopIndex: currentStopIndex,
  );
}

/// Reloads trip history and syncs active trip state from Supabase.
Future<void> refreshDriverAppData(BuildContext context) async {
  final auth = context.read<AuthProvider>();
  final profileId = auth.currentUser?.id;
  final history = context.read<DriverHistoryProvider>();
  final sessionProv = context.read<DriverSessionProvider>();

  await history.loadSessions();

  if (profileId == null || profileId.isEmpty) {
    return;
  }

  final tripService = TripService();
  final routeService = RouteService();

  final driverId = await tripService.getDriverIdForProfile(profileId);
  if (driverId == null || driverId.isEmpty) {
    sessionProv.clearActiveSession();
    return;
  }

  final activeRows = await tripService.fetchActiveTripsForDriver(driverId);
  final route = await routeService.getAssignedRouteForDriver(profileId);

  if (activeRows.isEmpty) {
    sessionProv.clearActiveSession();
    return;
  }

  sessionProv.syncActiveSessionFromRealtime(
    driverSessionFromActiveTripRow(activeRows.first, route),
  );
}
