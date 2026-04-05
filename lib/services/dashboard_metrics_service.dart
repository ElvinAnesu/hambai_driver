import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class DashboardTodayMetrics {
  const DashboardTodayMetrics({
    required this.todayTrips,
    required this.todayRidesCollected,
  });

  final int todayTrips;
  final int todayRidesCollected;
}

class DashboardMetricsService {
  Future<DashboardTodayMetrics> fetchTodayMetricsForProfile(String profileId) async {
    final driverRow = await sb.Supabase.instance.client
        .from('drivers')
        .select('id')
        .eq('profile_id', profileId)
        .maybeSingle();

    if (driverRow == null) {
      return const DashboardTodayMetrics(todayTrips: 0, todayRidesCollected: 0);
    }

    final driverId = driverRow['id'] as String?;
    if (driverId == null || driverId.isEmpty) {
      return const DashboardTodayMetrics(todayTrips: 0, todayRidesCollected: 0);
    }

    final nowLocal = DateTime.now();
    final startOfDayLocal = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
    final endOfDayLocal = startOfDayLocal.add(const Duration(days: 1));
    final startUtcIso = startOfDayLocal.toUtc().toIso8601String();
    final endUtcIso = endOfDayLocal.toUtc().toIso8601String();

    final tripRows = await sb.Supabase.instance.client
        .from('trips')
        .select('id')
        .eq('driver_id', driverId)
        .gte('started_at', startUtcIso)
        .lt('started_at', endUtcIso);

    final tripIds = (tripRows as List<dynamic>)
        .map((row) => row['id'] as String?)
        .whereType<String>()
        .toList();

    if (tripIds.isEmpty) {
      return const DashboardTodayMetrics(todayTrips: 0, todayRidesCollected: 0);
    }

    final rideRows = await sb.Supabase.instance.client
        .from('rides')
        .select('id')
        .inFilter('trip_id', tripIds);

    return DashboardTodayMetrics(
      todayTrips: tripIds.length,
      todayRidesCollected: (rideRows as List<dynamic>).length,
    );
  }
}
