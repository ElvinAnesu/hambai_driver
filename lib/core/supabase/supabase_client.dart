import 'package:supabase_flutter/supabase_flutter.dart';

abstract class DriverSupabaseConfig {
  static const String url = 'https://pjxzdkgtgtlowrucovui.supabase.co';
  static const String anonKey =
      'sb_publishable_HH93hWY6Bu4vcRQ1yIN-vg_CFZjGuP6';
}

class DriverSupabase {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: DriverSupabaseConfig.url,
      anonKey: DriverSupabaseConfig.anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
