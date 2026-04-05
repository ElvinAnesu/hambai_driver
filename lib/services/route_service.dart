import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../models/location.dart';
import '../models/predefined_route.dart';

class RouteService {
  Future<PredefinedRoute?> getAssignedRouteForDriver(String profileId) async {
    final driverRow = await sb.Supabase.instance.client
        .from('drivers')
        .select('id')
        .eq('profile_id', profileId)
        .maybeSingle();

    if (driverRow == null) {
      return null;
    }

    final driverId = driverRow['id'] as String?;
    if (driverId == null || driverId.isEmpty) {
      return null;
    }

    final assignmentRow = await sb.Supabase.instance.client
        .from('driver_route_assignments')
        .select('route_id')
        .eq('driver_id', driverId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (assignmentRow == null) {
      return null;
    }

    final routeId = assignmentRow['route_id'] as String?;
    if (routeId == null || routeId.isEmpty) {
      return null;
    }

    final routeRow = await sb.Supabase.instance.client
        .from('routes')
        .select('id, display_name, is_active')
        .eq('id', routeId)
        .eq('is_active', true)
        .maybeSingle();

    if (routeRow == null) {
      return null;
    }

    final routeStopsRows = await sb.Supabase.instance.client
        .from('route_stops')
        .select('id, stopping_point_id, stop_order')
        .eq('route_id', routeId)
        .order('stop_order', ascending: true);

    final stopRows = (routeStopsRows as List<dynamic>)
        .cast<Map<String, dynamic>>();
    if (stopRows.isEmpty) {
      return PredefinedRoute(
        id: routeId,
        displayName: routeRow['display_name'] as String,
        stops: const <Location>[],
      );
    }

    final stopIds = stopRows
        .map((row) => row['stopping_point_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();

    final stoppingPointsRows = await sb.Supabase.instance.client
        .from('stopping_points')
        .select('id, name, location_id')
        .inFilter('id', stopIds);

    final points = (stoppingPointsRows as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final pointsById = <String, Map<String, dynamic>>{};
    for (final row in points) {
      final id = row['id'] as String?;
      if (id != null) {
        pointsById[id] = row;
      }
    }

    final locationIds = points
        .map((row) => row['location_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();

    final locationNameById = <String, String>{};
    if (locationIds.isNotEmpty) {
      final locationsRows = await sb.Supabase.instance.client
          .from('locations')
          .select('id, name')
          .inFilter('id', locationIds);
      for (final row in (locationsRows as List<dynamic>).cast<Map<String, dynamic>>()) {
        final id = row['id'] as String?;
        final name = row['name'] as String?;
        if (id != null && name != null) {
          locationNameById[id] = name;
        }
      }
    }

    final orderedStops = <Location>[];
    for (final stop in stopRows) {
      final routeStopId = stop['id'] as String?;
      final stopId = stop['stopping_point_id'] as String?;
      if (routeStopId == null || stopId == null) continue;
      final point = pointsById[stopId];
      if (point == null) continue;
      final locationId = point['location_id'] as String?;
      final locationName = locationId != null ? locationNameById[locationId] : null;
      orderedStops.add(
        Location(
          id: routeStopId,
          name: point['name'] as String? ?? 'Unknown stop',
          address: locationName,
        ),
      );
    }

    return PredefinedRoute(
      id: routeId,
      displayName: routeRow['display_name'] as String,
      stops: orderedStops,
    );
  }
}
