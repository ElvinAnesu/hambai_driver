import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class StartTripResult {
  const StartTripResult._({
    required this.ok,
    this.tripId,
    this.driverCode,
    this.message,
  });

  final bool ok;
  final String? tripId;
  final String? driverCode;
  final String? message;

  const StartTripResult.started({required String tripId, String? driverCode})
      : this._(ok: true, tripId: tripId, driverCode: driverCode);

  const StartTripResult.failed(String message)
      : this._(ok: false, message: message);
}

class TripService {
  static const String activeTripBlockedMessage =
      'Complete current trip before starting another trip';

  Future<String?> getDriverIdForProfile(String profileId) async {
    final driverRow = await sb.Supabase.instance.client
        .from('drivers')
        .select('id')
        .eq('profile_id', profileId)
        .maybeSingle();
    return driverRow?['id'] as String?;
  }

  Stream<List<Map<String, dynamic>>> watchActiveTripsForDriver(String driverId) {
    return sb.Supabase.instance.client
        .from('trips')
        .stream(primaryKey: ['id'])
        .eq('driver_id', driverId)
        .map(
          (rows) => rows
              .map((row) => Map<String, dynamic>.from(row))
              .where((row) => row['status'] == 'active')
              .toList(),
        );
  }

  /// One-shot fetch of active trips for the driver (same filter as the realtime stream).
  Future<List<Map<String, dynamic>>> fetchActiveTripsForDriver(String driverId) async {
    final response = await sb.Supabase.instance.client
        .from('trips')
        .select()
        .eq('driver_id', driverId)
        .eq('status', 'active');
    final list = response as List<dynamic>? ?? const [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<StartTripResult> startTrip({
    required String profileId,
    required String routeId,
    required String direction,
  }) async {
    final driverRow = await sb.Supabase.instance.client
        .from('drivers')
        .select('id, driver_code')
        .eq('profile_id', profileId)
        .maybeSingle();

    if (driverRow == null) {
      return const StartTripResult.failed('Driver profile not found');
    }

    final driverId = driverRow['id'] as String?;
    if (driverId == null || driverId.isEmpty) {
      return const StartTripResult.failed('Driver profile not found');
    }

    final activeTrip = await sb.Supabase.instance.client
        .from('trips')
        .select('id')
        .eq('driver_id', driverId)
        .eq('status', 'active')
        .limit(1)
        .maybeSingle();

    if (activeTrip != null) {
      return const StartTripResult.failed(activeTripBlockedMessage);
    }

    final inserted = await sb.Supabase.instance.client
        .from('trips')
        .insert({
          'driver_id': driverId,
          'route_id': routeId,
          'status': 'active',
          'current_stop_index': 0,
          'direction': direction,
        })
        .select('id')
        .single();

    final tripId = inserted['id'] as String?;
    if (tripId == null || tripId.isEmpty) {
      return const StartTripResult.failed('Failed to create trip');
    }

    return StartTripResult.started(
      tripId: tripId,
      driverCode: driverRow['driver_code'] as String?,
    );
  }

  Future<void> endTrip(String tripId) async {
    await completeTrip(tripId: tripId, status: 'ended');
  }

  Future<void> completeTrip({
    required String tripId,
    required String status,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await sb.Supabase.instance.client
        .from('trips')
        .update({
          'status': status,
          'ended_at': now,
          'updated_at': now,
        })
        .eq('id', tripId)
        .eq('status', 'active');
  }

  Future<void> updateCurrentStopIndex({
    required String tripId,
    required int currentStopIndex,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await sb.Supabase.instance.client
        .from('trips')
        .update({
          'current_stop_index': currentStopIndex,
          'updated_at': now,
        })
        .eq('id', tripId)
        .eq('status', 'active');
  }
}
