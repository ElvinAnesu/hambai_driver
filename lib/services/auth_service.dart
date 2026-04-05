import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../models/user.dart' as app;

/// Driver auth service backed by Supabase Auth.
class MockAuthService {
  static const _keyOnboardingComplete = 'driver_onboarding_complete';

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingComplete, true);
  }

  Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingComplete) ?? false;
  }

  Future<app.User?> loadUser() async {
    final authUser = sb.Supabase.instance.client.auth.currentUser;
    if (authUser == null) return null;
    return _mapSupabaseUser(authUser);
  }

  /// Signs in with Supabase Auth using email and password.
  Future<app.User> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final result = await sb.Supabase.instance.client.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );

    final authUser = result.user ?? sb.Supabase.instance.client.auth.currentUser;
    if (authUser == null) {
      throw Exception('Login failed');
    }

    return _mapSupabaseUser(authUser);
  }

  Future<void> updateProfile({String? fullName, String? avatarUrl}) async {
    final current = sb.Supabase.instance.client.auth.currentUser;
    if (current == null) return;
    final existingMeta = current.userMetadata ?? <String, dynamic>{};
    final nextMeta = <String, dynamic>{...existingMeta};
    final fullNameValue = fullName?.trim();
    if (fullNameValue != null) {
      nextMeta['full_name'] = fullNameValue;
    }
    final avatarValue = avatarUrl?.trim();
    if (avatarValue != null) {
      nextMeta['avatar_url'] = avatarValue;
    }

    await sb.Supabase.instance.client.auth.updateUser(
      sb.UserAttributes(data: nextMeta),
    );
  }

  Future<void> uploadAvatar({
    required Uint8List bytes,
    required String fileExtension,
    required String contentType,
  }) async {
    final client = sb.Supabase.instance.client;
    final current = client.auth.currentUser;
    if (current == null) {
      throw Exception('User is not authenticated');
    }

    final normalizedExt = fileExtension.trim().toLowerCase();
    final objectPath =
        '${current.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.$normalizedExt';

    await client.storage.from('user_avatars').uploadBinary(
          objectPath,
          bytes,
          fileOptions: sb.FileOptions(
            contentType: contentType,
            upsert: true,
          ),
        );

    final publicUrl = client.storage.from('user_avatars').getPublicUrl(objectPath);
    await updateProfile(avatarUrl: publicUrl);
  }

  Future<void> logout() async {
    await sb.Supabase.instance.client.auth.signOut();
  }

  Future<void> deleteAccount() async {
    await logout();
  }

  app.User _mapSupabaseUser(sb.User user) {
    final meta = user.userMetadata ?? <String, dynamic>{};
    final fullNameRaw = (meta['full_name'] ?? meta['name'] ?? '') as Object;
    final avatarRaw = (meta['avatar_url'] ?? '') as Object;
    final fullName = fullNameRaw.toString().trim();
    final avatarUrl = avatarRaw.toString().trim();
    return app.User(
      id: user.id,
      phone: (user.email ?? user.phone ?? '').trim(),
      fullName: fullName.isEmpty ? null : fullName,
      avatarUrl: avatarUrl.isEmpty ? null : avatarUrl,
    );
  }
}
