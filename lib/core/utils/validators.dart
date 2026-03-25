/// Validate a Russian phone number.
/// Returns null if valid, error message otherwise.
/// Accepts formats: +7XXXXXXXXXX, 8XXXXXXXXXX, 9XXXXXXXXXX (10 digits without code).
String? validatePhone(String phone) {
  if (phone.isEmpty) return 'Введите номер телефона';

  final digits = phone.replaceAll(RegExp(r'[^\d]'), '');

  if (digits.length == 11 &&
      (digits.startsWith('7') || digits.startsWith('8'))) {
    return null;
  }
  if (digits.length == 10 && digits.startsWith('9')) {
    return null;
  }

  return 'Неверный формат номера телефона';
}

/// Validate SMS confirmation code (4–6 digits).
/// Returns null if valid, error message otherwise.
String? validateSmsCode(String code) {
  if (code.isEmpty) return 'Введите код';

  final trimmed = code.trim();
  if (!RegExp(r'^\d{4,6}$').hasMatch(trimmed)) {
    return 'Код должен содержать 4–6 цифр';
  }

  return null;
}

/// Validate user display name.
/// Returns null if valid, error message otherwise.
String? validateName(String name) {
  if (name.isEmpty) return 'Введите имя';

  final trimmed = name.trim();
  if (trimmed.length < 2) return 'Имя должно быть не менее 2 символов';
  if (trimmed.length > 50) return 'Имя должно быть не более 50 символов';

  return null;
}
