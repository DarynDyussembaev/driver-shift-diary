import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'models.dart';

class ApiException implements Exception {
  const ApiException(this.message, this.status);

  final String message;
  final int status;

  @override
  String toString() => message;
}

// Адрес API можно задать при сборке: --dart-define=API_URL=http://192.168.1.10:8000
const _apiUrlFromEnv = String.fromEnvironment('API_URL');

String defaultBaseUrl() {
  if (_apiUrlFromEnv.isNotEmpty) return _apiUrlFromEnv;
  // В браузере приложение раздаёт nginx, он же проксирует /api на бэкенд.
  if (kIsWeb) return Uri.base.origin;
  // 10.0.2.2 — это localhost компьютера, если смотреть из эмулятора Android.
  return 'http://10.0.2.2:8000';
}

class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? defaultBaseUrl();

  final http.Client _client;
  final String _baseUrl;

  Future<List<String>> fetchDays() async {
    final body = await _request('GET', '/api/days');
    return (body as List<dynamic>).cast<String>();
  }

  Future<DayReport> fetchDay(String day) async {
    final body = await _request('GET', '/api/days/$day');
    return DayReport.fromJson(body as Map<String, dynamic>);
  }

  Future<Trip> createTrip(Trip trip) async {
    final body = await _request('POST', '/api/trips', json: trip.toJson());
    return Trip.fromJson(body as Map<String, dynamic>);
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? json,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final http.Response response;
    try {
      response = method == 'POST'
          ? await _client.post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(json),
            )
          : await _client.get(uri);
    } catch (_) {
      throw const ApiException(
        'Сервер недоступен. Проверьте, что бэкенд запущен.',
        0,
      );
    }

    dynamic body;
    try {
      // bodyBytes, а не body: без charset в заголовке http читает ответ как latin1
      // и ломает кириллицу.
      body = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      body = null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _readDetail(body) ?? 'Ошибка сервера (${response.statusCode})',
        response.statusCode,
      );
    }
    if (body == null) {
      throw ApiException('Некорректный ответ сервера', response.statusCode);
    }
    return body;
  }
}

// FastAPI отдаёт detail строкой (409) или списком ошибок валидации (422).
String? _readDetail(dynamic body) {
  if (body is! Map<String, dynamic>) return null;
  final detail = body['detail'];
  if (detail is String) return detail;
  if (detail is List) {
    final messages = [
      for (final item in detail)
        if (item is Map && item['msg'] is String) item['msg'] as String,
    ];
    return messages.isEmpty ? null : messages.join('; ');
  }
  return null;
}
