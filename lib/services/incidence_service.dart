import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class IncidenceService {
  Future<void> submitIncidence({
    required String incidenceType,
    required String details,
  }) async {
    final client = sb.Supabase.instance.client;
    final profileId = client.auth.currentUser?.id;
    if (profileId == null || profileId.isEmpty) {
      throw Exception('User is not authenticated');
    }

    final driverRow = await client
        .from('drivers')
        .select('id')
        .eq('profile_id', profileId)
        .maybeSingle();
    final driverId = driverRow?['id'] as String?;
    if (driverId == null || driverId.isEmpty) {
      throw Exception('Driver profile not found');
    }

    await client.from('incidences').insert({
      'driver_id': driverId,
      'incidence_type': incidenceType,
      'details': details.trim(),
    });
  }
}
