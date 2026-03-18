/// Form and input validators.
abstract class Validators {
  static String? phone(String? value) {
    if (value == null || value.isEmpty) return 'Enter your phone number';
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 9) return 'Enter a valid phone number';
    return null;
  }

  static String? otp(String? value, {int length = 6}) {
    if (value == null || value.length != length) {
      return 'Enter $length digits';
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) return 'OTP must be digits only';
    return null;
  }

  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? fullName(String? value) {
    final err = required(value, 'Full name');
    if (err != null) return err;
    if (value!.trim().length < 2) return 'Enter at least 2 characters';
    return null;
  }
}
