# Flutter-клиент

Второй клиент к тому же API: тот же экран, что и в React-версии. Общее описание проекта — в [README в корне](../README.md).

## Запуск

Бэкенд должен быть запущен (см. корневой README).

**В браузере через Docker** — Flutter SDK ставить не нужно:

```bash
docker compose --profile flutter up --build
```

Откроется на http://localhost:8081. Первая сборка долгая: образ с Flutter SDK весит несколько ГБ.

**С установленным Flutter SDK:**

```bash
cd mobile
flutter pub get

# эмулятор Android — адрес API по умолчанию http://10.0.2.2:8000
flutter run

# браузер или реальное устройство — адрес API задаётся явно
flutter run -d chrome --dart-define=API_URL=http://localhost:8000
flutter run --dart-define=API_URL=http://<ip-компьютера>:8000
```

## Тесты

```bash
flutter test
```

- `format_test.dart` — форматирование денег и дат, переход между днями;
- `validation_test.dart` — проверка формы;
- `api_test.dart` — разбор ответов, ошибки сервера, повторная отправка с тем же `id`;
- `widget_test.dart` — экран: сводка, переключение дня, ошибка формы.

## Что проверено

Анализатор, тесты и веб-сборка. На Android и iOS приложение не запускалось.
