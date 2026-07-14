/// Utility class for form validation
class Validators {
  Validators._();

  /// Validate required field
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null
          ? '$fieldName is required'
          : 'This field is required';
    }
    return null;
  }

  /// Validate number input
  static String? number(
    String? value, {
    String? fieldName,
    bool allowZero = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null
          ? '$fieldName is required'
          : 'This field is required';
    }

    final number = double.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }

    if (!allowZero && number == 0) {
      return 'Value cannot be zero';
    }

    if (number < 0) {
      return 'Value cannot be negative';
    }

    return null;
  }

  /// Validate positive number
  static String? positiveNumber(String? value, {String? fieldName}) {
    final result = number(value, fieldName: fieldName, allowZero: false);
    if (result != null) return result;

    final num = double.parse(value!);
    if (num <= 0) {
      return 'Value must be greater than zero';
    }

    return null;
  }

  /// Validate integer input
  static String? integer(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null
          ? '$fieldName is required'
          : 'This field is required';
    }

    final intValue = int.tryParse(value);
    if (intValue == null) {
      return 'Please enter a whole number';
    }

    if (intValue < 0) {
      return 'Value cannot be negative';
    }

    return null;
  }

  /// Validate IMEI number (15 digits)
  static String? imei(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'IMEI number is required';
    }

    final cleaned = value.replaceAll(RegExp(r'\D'), '');

    if (cleaned.length != 15) {
      return 'IMEI must be exactly 15 digits';
    }

    // Accept any 15-digit number as valid IMEI
    return null;
  }

  /// Validate product code (alphanumeric, no spaces)
  static String? productCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Product code is required';
    }

    if (value.length < 3) {
      return 'Product code must be at least 3 characters';
    }

    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value)) {
      return 'Product code can only contain letters, numbers, underscores, and hyphens';
    }

    return null;
  }

  /// Validate phone number (Bangladesh format)
  static String? phoneNumber(String? value, {bool isRequired = true}) {
    if (value == null || value.trim().isEmpty) {
      if (isRequired) {
        return 'Phone number is required';
      }
      return null;
    }

    final cleaned = value.replaceAll(RegExp(r'\D'), '');

    // Bangladesh phone numbers: 11 digits starting with 01
    if (cleaned.length == 11 && cleaned.startsWith('01')) {
      return null;
    }

    // With country code: 13 digits starting with 8801
    if (cleaned.length == 13 && cleaned.startsWith('8801')) {
      return null;
    }

    return 'Please enter a valid phone number';
  }

  /// Validate PIN (4-6 digits)
  static String? pin(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'PIN is required';
    }

    if (!RegExp(r'^\d{4,6}$').hasMatch(value)) {
      return 'PIN must be 4-6 digits';
    }

    return null;
  }

  /// Validate password
  static String? password(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  /// Validate percentage (0-100)
  static String? percentage(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional by default
    }

    final num = double.tryParse(value);
    if (num == null) {
      return 'Please enter a valid percentage';
    }

    if (num < 0 || num > 100) {
      return 'Percentage must be between 0 and 100';
    }

    return null;
  }

  /// Validate quantity (positive integer)
  static String? quantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Quantity is required';
    }

    final qty = int.tryParse(value);
    if (qty == null || qty < 0) {
      return 'Please enter a valid quantity';
    }

    return null;
  }

  /// Validate against minimum value
  static String? minValue(String? value, double min, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final num = double.tryParse(value);
    if (num == null) {
      return 'Please enter a valid number';
    }

    if (num < min) {
      return '${fieldName ?? 'Value'} must be at least $min';
    }

    return null;
  }

  /// Validate against maximum value
  static String? maxValue(String? value, double max, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final num = double.tryParse(value);
    if (num == null) {
      return 'Please enter a valid number';
    }

    if (num > max) {
      return '${fieldName ?? 'Value'} must not exceed $max';
    }

    return null;
  }
}
