import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class DriverRatingService {
  Future<double?> getAverageRatingForCurrentDriver() async {
    final client = sb.Supabase.instance.client;
    final profileId = client.auth.currentUser?.id;
    if (profileId == null || profileId.isEmpty) {
      return null;
    }

    final driverRow = await client
        .from('drivers')
        .select('id')
        .eq('profile_id', profileId)
        .maybeSingle();
    final driverId = driverRow?['id'] as String?;
    if (driverId == null || driverId.isEmpty) {
      return null;
    }

    final response = await client
        .from('rides')
        .select('driver_rating, trips!inner(driver_id)')
        .eq('trips.driver_id', driverId)
        .not('driver_rating', 'is', null);

    final rows = (response as List<dynamic>).cast<Map<String, dynamic>>();
    if (rows.isEmpty) {
      return null;
    }

    var total = 0.0;
    var count = 0;
    for (final row in rows) {
      final value = row['driver_rating'];
      if (value is num) {
        total += value.toDouble();
        count += 1;
      }
    }

    if (count == 0) {
      return null;
    }

    return total / count;
  }
}
