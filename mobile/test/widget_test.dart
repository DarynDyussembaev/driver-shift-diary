import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shift_diary/api.dart';
import 'package:shift_diary/main.dart';

const _emptySummary = {
  'trips_count': 0,
  'revenue': 0,
  'commission': 0,
  'net': 0,
  'cash': {'count': 0, 'amount': 0},
  'card': {'count': 0, 'amount': 0},
};

const _october1 = {
  'date': '2026-10-01',
  'summary': {
    'trips_count': 2,
    'revenue': 3900,
    'commission': 585,
    'net': 3315,
    'cash': {'count': 1, 'amount': 1500},
    'card': {'count': 1, 'amount': 2400},
  },
  'trips': [
    {
      'id': 't1',
      'start': '2026-10-01T08:10:00+05:00',
      'end': '2026-10-01T08:32:00+05:00',
      'amount': 2400,
      'payment': 'card',
      'commission': 360,
    },
    {
      'id': 't2',
      'start': '2026-10-01T09:05:00+05:00',
      'end': '2026-10-01T09:20:00+05:00',
      'amount': 1500,
      'payment': 'cash',
      'commission': 225,
    },
  ],
};

/// Сервер-заглушка: поездки есть только за 1 октября.
ApiClient _fakeApi(List<String> requestedPaths) {
  return ApiClient(
    baseUrl: 'http://api.test',
    client: MockClient((request) async {
      requestedPaths.add(request.url.path);
      final Object body;
      if (request.url.path == '/api/days') {
        body = ['2026-10-01'];
      } else if (request.url.path == '/api/days/2026-10-01') {
        body = _october1;
      } else {
        body = {
          'date': request.url.pathSegments.last,
          'summary': _emptySummary,
          'trips': <Object>[],
        };
      }
      return http.Response.bytes(utf8.encode(jsonEncode(body)), 200);
    }),
  );
}

void main() {
  testWidgets('shows summary and trips of the latest day', (tester) async {
    await tester.pumpWidget(ShiftDiaryApp(api: _fakeApi([])));
    await tester.pumpAndSettle();

    expect(find.text('Четверг, 1 октября 2026'), findsOneWidget);
    expect(find.text('На руки'), findsOneWidget);
    expect(find.text('3 315 ₸'), findsOneWidget);
    expect(find.text('Наличные · 1'), findsOneWidget);
    expect(find.text('08:10 – 08:32'), findsOneWidget);
    expect(find.text('09:05 – 09:20'), findsOneWidget);
  });

  testWidgets('switches to the next day', (tester) async {
    final paths = <String>[];
    await tester.pumpWidget(ShiftDiaryApp(api: _fakeApi(paths)));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    expect(paths.last, '/api/days/2026-10-02');
    expect(find.text('Пятница, 2 октября 2026'), findsOneWidget);
    expect(find.text('За этот день поездок нет.'), findsOneWidget);
    expect(find.text('08:10 – 08:32'), findsNothing);
  });

  testWidgets('shows form error instead of sending invalid trip', (tester) async {
    final paths = <String>[];
    await tester.pumpWidget(ShiftDiaryApp(api: _fakeApi(paths)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Поездка'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Добавить'));
    await tester.pumpAndSettle();

    expect(find.text('Укажите время начала и окончания'), findsOneWidget);
    expect(paths, isNot(contains('/api/trips')));
  });
}
