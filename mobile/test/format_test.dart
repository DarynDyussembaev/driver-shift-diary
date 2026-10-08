import 'package:flutter_test/flutter_test.dart';
import 'package:shift_diary/format.dart';

void main() {
  test('formatMoney groups thousands', () {
    expect(formatMoney(0), '0 ₸');
    expect(formatMoney(999), '999 ₸');
    expect(formatMoney(1500), '1 500 ₸');
    expect(formatMoney(12400), '12 400 ₸');
    expect(formatMoney(1234567), '1 234 567 ₸');
  });

  test('formatTime shows time as recorded in the trip', () {
    expect(formatTime('2026-10-01T08:10:00+05:00'), '08:10');
  });

  test('tripTime builds ISO time with offset', () {
    expect(tripTime('2026-10-01', 8, 5), '2026-10-01T08:05:00+05:00');
  });

  test('shiftDay crosses month and year boundaries', () {
    expect(shiftDay('2026-10-01', 1), '2026-10-02');
    expect(shiftDay('2026-10-01', -1), '2026-09-30');
    expect(shiftDay('2026-12-31', 1), '2027-01-01');
    expect(shiftDay('2028-02-28', 1), '2028-02-29');
  });

  test('formatDay and formatShortDay are in Russian', () {
    expect(formatDay('2026-10-01'), 'Четверг, 1 октября 2026');
    expect(formatShortDay('2026-10-03'), '3 окт');
  });

  test('defaultCommission is 15% rounded', () {
    expect(defaultCommission(2400), 360);
    expect(defaultCommission(1500), 225);
    expect(defaultCommission(999), 150);
  });

  test('newTripId is unique 32-char hex', () {
    final first = newTripId();
    expect(first, matches(RegExp(r'^[0-9a-f]{32}$')));
    expect(newTripId(), isNot(first));
  });
}
