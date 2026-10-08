import 'package:flutter_test/flutter_test.dart';
import 'package:shift_diary/validation.dart';

void main() {
  String? check({
    int? start = 8 * 60,
    int? end = 8 * 60 + 30,
    int? amount = 2000,
    int? commission = 300,
  }) {
    return validateTrip(
      startMinutes: start,
      endMinutes: end,
      amount: amount,
      commission: commission,
    );
  }

  test('valid trip passes', () {
    expect(check(), isNull);
  });

  test('time is required', () {
    expect(check(start: null), isNotNull);
    expect(check(end: null), isNotNull);
  });

  test('end must be later than start', () {
    expect(check(start: 600, end: 599), isNotNull);
    expect(check(start: 600, end: 600), isNotNull);
  });

  test('amount must be positive', () {
    expect(check(amount: 0), isNotNull);
    expect(check(amount: null), isNotNull);
  });

  test('commission must be between zero and amount', () {
    expect(check(commission: -1), isNotNull);
    expect(check(amount: 1000, commission: 1001), isNotNull);
    expect(check(amount: 1000, commission: 1000), isNull);
    expect(check(commission: 0), isNull);
  });
}
