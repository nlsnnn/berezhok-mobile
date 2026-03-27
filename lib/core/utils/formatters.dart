import 'package:intl/intl.dart';

/// Format price in rubles: "199 ₽" or "199.50 ₽"
String formatPrice(double price) {
  final formatted =
      price == price.roundToDouble() ? price.toInt().toString() : price.toStringAsFixed(2);
  return '$formatted ₽';
}

/// Format distance: "850 м" or "1.2 км"
String formatDistance(double meters) {
  if (meters < 1000) {
    return '${meters.round()} м';
  }
  final km = meters / 1000;
  final formatted =
      km == km.roundToDouble() ? km.toInt().toString() : km.toStringAsFixed(1);
  return '$formatted км';
}

/// Format Russian phone: "+7 (900) 123-45-67"
String formatPhone(String phone) {
  // Strip everything except digits
  final digits = phone.replaceAll(RegExp(r'[^\d]'), '');

  // Expect 11 digits starting with 7 or 8, or 10 digits (without country code)
  final String normalized;
  if (digits.length == 11 && (digits.startsWith('7') || digits.startsWith('8'))) {
    normalized = digits.substring(1);
  } else if (digits.length == 10) {
    normalized = digits;
  } else {
    return phone; // can't format, return as-is
  }

  return '+7 (${normalized.substring(0, 3)}) '
      '${normalized.substring(3, 6)}-'
      '${normalized.substring(6, 8)}-'
      '${normalized.substring(8, 10)}';
}

final _timeFormat = DateFormat('HH:mm');
final _dayMonthFormat = DateFormat('d MMM', 'ru');

/// Format pickup window: "Сегодня, 18:00–19:00" / "Завтра, 18:00–19:00" / "25 янв, 18:00–19:00"
String formatPickupTime(DateTime start, DateTime end) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final startDay = DateTime(start.year, start.month, start.day);

  final String dayLabel;
  if (startDay == today) {
    dayLabel = 'Сегодня';
  } else if (startDay == today.add(const Duration(days: 1))) {
    dayLabel = 'Завтра';
  } else {
    dayLabel = _dayMonthFormat.format(start);
  }

  return '$dayLabel, ${_timeFormat.format(start)}–${_timeFormat.format(end)}';
}

/// Format pickup start time only: "Сегодня, 18:00" / "Завтра, 18:00" / "25 янв, 18:00"
String formatPickupTimeStart(DateTime start) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final startDay = DateTime(start.year, start.month, start.day);

  final String dayLabel;
  if (startDay == today) {
    dayLabel = 'Сегодня';
  } else if (startDay == today.add(const Duration(days: 1))) {
    dayLabel = 'Завтра';
  } else {
    dayLabel = _dayMonthFormat.format(start);
  }

  return '$dayLabel, ${_timeFormat.format(start)}';
}

/// Format relative time in Russian: "5 мин назад", "2 часа назад", "вчера", "25 янв"
String formatRelativeTime(DateTime dateTime) {
  final diff = timeAgo(dateTime);

  if (diff.inSeconds < 60) {
    return 'только что';
  }
  if (diff.inMinutes < 60) {
    return '${_pluralize(diff.inMinutes, 'минуту', 'минуты', 'минут')} назад';
  }
  if (diff.inHours < 24) {
    return '${_pluralize(diff.inHours, 'час', 'часа', 'часов')} назад';
  }
  if (diff.inDays == 1) {
    return 'вчера';
  }
  if (diff.inDays < 7) {
    return '${_pluralize(diff.inDays, 'день', 'дня', 'дней')} назад';
  }
  return _dayMonthFormat.format(dateTime);
}

/// Returns the Duration since [dateTime] until now.
Duration timeAgo(DateTime dateTime) => DateTime.now().difference(dateTime);

/// Russian pluralization helper for numeric phrases.
/// e.g. _pluralize(5, 'минуту', 'минуты', 'минут') => "5 минут"
String _pluralize(int n, String one, String few, String many) {
  final mod10 = n % 10;
  final mod100 = n % 100;

  final String form;
  if (mod100 >= 11 && mod100 <= 19) {
    form = many;
  } else if (mod10 == 1) {
    form = one;
  } else if (mod10 >= 2 && mod10 <= 4) {
    form = few;
  } else {
    form = many;
  }

  return '$n $form';
}
