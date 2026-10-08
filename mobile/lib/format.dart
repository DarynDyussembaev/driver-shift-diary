import 'dart:math';

// Смещение, в котором водитель вводит время новых поездок (Казахстан, UTC+5).
const tzOffset = '+05:00';

// Комиссия агрегатора по умолчанию — в примере данных она равна 15% от суммы.
const defaultCommissionRate = 0.15;

int defaultCommission(int amount) => (amount * defaultCommissionRate).round();

String _two(int value) => value.toString().padLeft(2, '0');

/// 12400 -> "12 400 ₸" (разделитель — неразрывный пробел).
String formatMoney(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return '$buffer ₸';
}

/// "2026-10-01T08:10:00+05:00" -> "08:10".
String formatTime(String iso) => iso.substring(11, 16);

/// Собирает время поездки в выбранном дне: ("2026-10-01", 8, 10) -> ISO со смещением.
String tripTime(String day, int hour, int minute) =>
    '${day}T${_two(hour)}:${_two(minute)}:00$tzOffset';

// Дни — это строки YYYY-MM-DD. Считаем их в UTC, чтобы часовой пояс устройства
// и переходы на летнее время не сдвигали дату.
DateTime parseDay(String day) {
  final parts = day.split('-').map(int.parse).toList();
  return DateTime.utc(parts[0], parts[1], parts[2]);
}

String dayOf(DateTime date) =>
    '${date.year}-${_two(date.month)}-${_two(date.day)}';

String shiftDay(String day, int delta) {
  final date = parseDay(day);
  return dayOf(DateTime.utc(date.year, date.month, date.day + delta));
}

String today() => dayOf(DateTime.now());

const _weekdays = [
  'Понедельник',
  'Вторник',
  'Среда',
  'Четверг',
  'Пятница',
  'Суббота',
  'Воскресенье',
];

const _months = [
  'января',
  'февраля',
  'марта',
  'апреля',
  'мая',
  'июня',
  'июля',
  'августа',
  'сентября',
  'октября',
  'ноября',
  'декабря',
];

const _shortMonths = [
  'янв',
  'фев',
  'мар',
  'апр',
  'мая',
  'июн',
  'июл',
  'авг',
  'сен',
  'окт',
  'ноя',
  'дек',
];

/// "2026-10-01" -> "Четверг, 1 октября 2026".
String formatDay(String day) {
  final date = parseDay(day);
  return '${_weekdays[date.weekday - 1]}, ${date.day} '
      '${_months[date.month - 1]} ${date.year}';
}

/// "2026-10-01" -> "1 окт".
String formatShortDay(String day) {
  final date = parseDay(day);
  return '${date.day} ${_shortMonths[date.month - 1]}';
}

final _random = Random.secure();

/// Случайный id поездки — ключ идемпотентности для POST /api/trips.
String newTripId() {
  return List.generate(16, (_) => _two16(_random.nextInt(256))).join();
}

String _two16(int byte) => byte.toRadixString(16).padLeft(2, '0');
