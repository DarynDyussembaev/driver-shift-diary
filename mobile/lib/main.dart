import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'api.dart';
import 'home_page.dart';

void main() {
  runApp(ShiftDiaryApp(api: ApiClient()));
}

class ShiftDiaryApp extends StatelessWidget {
  const ShiftDiaryApp({super.key, required this.api});

  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF1F6FEB);

    return MaterialApp(
      title: 'Дневник смен водителя',
      debugShowCheckedModeBanner: false,
      // Русская локаль нужна системным диалогам выбора даты и времени.
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(colorSchemeSeed: seed),
      darkTheme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.dark),
      home: HomePage(api: api),
    );
  }
}
