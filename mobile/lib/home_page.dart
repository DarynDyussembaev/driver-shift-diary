import 'package:flutter/material.dart';

import 'api.dart';
import 'format.dart';
import 'models.dart';
import 'trip_form.dart';
import 'widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.api});

  final ApiClient api;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _day;
  List<String> _daysWithTrips = [];
  DayReport? _report;
  String? _error;
  bool _loading = false;
  // Номер последнего запроса. Если день переключили быстрее, чем пришёл ответ,
  // устаревший ответ отбрасываем, иначе он затрёт данные нового дня.
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  // При старте открываем последний день, за который есть поездки.
  Future<void> _init() async {
    var day = today();
    try {
      final days = await widget.api.fetchDays();
      if (!mounted) return;
      _daysWithTrips = days;
      if (days.isNotEmpty) day = days.last;
    } on ApiException {
      if (!mounted) return;
    }
    await _selectDay(day);
  }

  Future<void> _loadDays() async {
    try {
      final days = await widget.api.fetchDays();
      if (mounted) setState(() => _daysWithTrips = days);
    } on ApiException {
      // Список дней — только подсказка для быстрых кнопок, без него можно жить.
    }
  }

  Future<void> _selectDay(String day) async {
    final requestId = ++_requestId;
    setState(() {
      _day = day;
      _loading = true;
      _error = null;
    });

    try {
      final report = await widget.api.fetchDay(day);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _report = report;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _report = null;
        _error = error.message;
        _loading = false;
      });
    }
  }

  Future<void> _pickDay() async {
    final current = parseDay(_day!);
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(current.year, current.month, current.day),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) _selectDay(dayOf(picked));
  }

  Future<void> _addTrip() async {
    final trip = await showModalBottomSheet<Trip>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SingleChildScrollView(
        // Поднимаем форму над экранной клавиатурой.
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: TripForm(day: _day!, api: widget.api),
      ),
    );
    if (trip == null || !mounted) return;
    _selectDay(_day!);
    _loadDays();
  }

  @override
  Widget build(BuildContext context) {
    final day = _day;

    return Scaffold(
      appBar: AppBar(title: const Text('Дневник смен водителя')),
      floatingActionButton: day == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _addTrip,
              icon: const Icon(Icons.add),
              label: const Text('Поездка'),
            ),
      body: day == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _selectDay(day),
              child: Center(
                // На широком экране (веб, планшет) контент не растягивается.
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: _buildContent(context, day),
                ),
              ),
            ),
    );
  }

  Widget _buildContent(BuildContext context, String day) {
    final theme = Theme.of(context);
    final report = _report;
    final error = _error;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        Row(
          children: [
            IconButton.filledTonal(
              onPressed: () => _selectDay(shiftDay(day, -1)),
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Предыдущий день',
            ),
            Expanded(
              child: TextButton(
                onPressed: _pickDay,
                child: Text(
                  formatDay(day),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
            IconButton.filledTonal(
              onPressed: () => _selectDay(shiftDay(day, 1)),
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Следующий день',
            ),
          ],
        ),
        if (_daysWithTrips.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final item in _daysWithTrips)
                ChoiceChip(
                  label: Text(formatShortDay(item)),
                  selected: item == day,
                  onSelected: (_) => _selectDay(item),
                ),
            ],
          ),
        ],
        // Полоска фиксированной высоты, чтобы контент не прыгал при загрузке.
        SizedBox(
          height: 16,
          child: _loading
              ? const Center(child: LinearProgressIndicator())
              : null,
        ),
        if (error != null)
          Card(
            color: theme.colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                error,
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
          ),
        if (report != null) ...[
          SummaryView(summary: report.summary),
          const SizedBox(height: 16),
          if (report.trips.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'За этот день поездок нет.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            )
          else
            Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final (index, trip) in report.trips.indexed) ...[
                    if (index > 0) const Divider(height: 1),
                    TripTile(trip: trip),
                  ],
                ],
              ),
            ),
        ],
      ],
    );
  }
}
