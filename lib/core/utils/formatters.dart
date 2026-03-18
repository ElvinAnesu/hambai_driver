import '../constants/app_constants.dart';

/// Input formatters and normalizers.
abstract class Formatters {
  /// Normalize phone to digits only; optionally ensure country code.
  static String normalizePhone(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('263')) return digits;
    if (digits.length >= 9) return '263${digits.substring(digits.length - 9)}';
    return digits;
  }

  /// Display phone with +263 prefix.
  static String displayPhone(String normalized) {
    final d = normalized.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('263') && d.length >= 12) {
      return '+${d.substring(0, 3)} ${d.substring(3)}';
    }
    return '${AppConstants.countryCode} $normalized';
  }
}
