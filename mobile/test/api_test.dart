import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shift_diary/api.dart';
import 'package:shift_diary/models.dart';

const _trip = Trip(
  id: 'abc',
  start: '2026-10-01T12:00:00+05:00',
  end: '2026-10-01T12:25:00+05:00',
  amount: 2000,
  payment: Payment.cash,
  commission: 300,
);

http.Response _json(Object body, [int status = 200]) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: {'content-type': 'application/json'},
  );
}

void main() {
  test('fetchDay parses report', () async {
    final api = ApiClient(
      baseUrl: 'http://api.test',
      client: MockClient((request) async {
        expect(request.url.toString(), 'http://api.test/api/days/2026-10-01');
        return _json({
          'date': '2026-10-01',
          'summary': {
            'trips_count': 1,
            'revenue': 2000,
            'commission': 300,
            'net': 1700,
            'cash': {'count': 1, 'amount': 2000},
            'card': {'count': 0, 'amount': 0},
          },
          'trips': [_trip.toJson()],
        });
      }),
    );

    final report = await api.fetchDay('2026-10-01');

    expect(report.summary.net, 1700);
    expect(report.summary.cash.count, 1);
    expect(report.trips.single.payment, Payment.cash);
    expect(report.trips.single.durationMinutes, 25);
  });

  test('createTrip sends id so that a retry is not duplicated', () async {
    final sentIds = <String>[];
    final api = ApiClient(
      baseUrl: 'http://api.test',
      client: MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        sentIds.add(body['id'] as String);
        return _json(body, sentIds.length == 1 ? 201 : 200);
      }),
    );

    await api.createTrip(_trip);
    await api.createTrip(_trip);

    expect(sentIds, ['abc', 'abc']);
  });

  test('server error text is passed to the user, including cyrillic', () async {
    final api = ApiClient(
      baseUrl: 'http://api.test',
      client: MockClient(
        (_) async => _json({'detail': 'Поездка уже существует'}, 409),
      ),
    );

    expect(
      () => api.createTrip(_trip),
      throwsA(
        isA<ApiException>()
            .having((e) => e.status, 'status', 409)
            .having((e) => e.message, 'message', 'Поездка уже существует'),
      ),
    );
  });

  test('validation errors are joined', () async {
    final api = ApiClient(
      baseUrl: 'http://api.test',
      client: MockClient(
        (_) async => _json({
          'detail': [
            {'msg': 'first'},
            {'msg': 'second'},
          ],
        }, 422),
      ),
    );

    expect(
      () => api.createTrip(_trip),
      throwsA(
        isA<ApiException>().having((e) => e.message, 'message', 'first; second'),
      ),
    );
  });

  test('network failure becomes ApiException', () async {
    final api = ApiClient(
      baseUrl: 'http://api.test',
      client: MockClient((_) async => throw http.ClientException('offline')),
    );

    expect(api.fetchDays, throwsA(isA<ApiException>()));
  });
}
