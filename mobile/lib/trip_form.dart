import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api.dart';
import 'format.dart';
import 'models.dart';
import 'validation.dart';

/// Форма добавления поездки. После успешного сохранения закрывается
/// и возвращает созданную поездку через Navigator.pop.
class TripForm extends StatefulWidget {
  const TripForm({super.key, required this.day, required this.api});

  final String day;
  final ApiClient api;

  @override
  State<TripForm> createState() => _TripFormState();
}

class _TripFormState extends State<TripForm> {
  final _amount = TextEditingController();
  final _commission = TextEditingController();

  TimeOfDay? _start;
  TimeOfDay? _end;
  Payment _payment = Payment.cash;
  // Пока комиссию не трогали руками, считаем её от суммы.
  bool _commissionEdited = false;
  // Ключ идемпотентности. Он живёт, пока данные формы не менялись: если запрос
  // оборвался и пользователь нажал «Добавить» ещё раз, уйдёт тот же id
  // и сервер не создаст вторую поездку.
  String _tripId = newTripId();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _commission.dispose();
    super.dispose();
  }

  void _changed(VoidCallback update) {
    setState(() {
      update();
      // Данные изменились — это уже другая поездка, ей нужен новый id.
      _tripId = newTripId();
      _error = null;
    });
  }

  void _onAmountChanged(String value) {
    _changed(() {
      if (_commissionEdited) return;
      final amount = int.tryParse(value);
      _commission.text =
          amount == null ? '' : defaultCommission(amount).toString();
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isStart ? _start : _end ?? _start) ?? TimeOfDay.now(),
      helpText: isStart ? 'Начало поездки' : 'Окончание поездки',
    );
    if (picked == null) return;
    _changed(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final start = _start;
    final end = _end;
    final amount = int.tryParse(_amount.text);
    final commission =
        _commission.text.isEmpty ? 0 : int.tryParse(_commission.text);

    final problem = validateTrip(
      startMinutes: start == null ? null : start.hour * 60 + start.minute,
      endMinutes: end == null ? null : end.hour * 60 + end.minute,
      amount: amount,
      commission: commission,
    );
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final trip = await widget.api.createTrip(
        Trip(
          id: _tripId,
          start: tripTime(widget.day, start!.hour, start.minute),
          end: tripTime(widget.day, end!.hour, end.minute),
          amount: amount!,
          payment: _payment,
          commission: commission!,
        ),
      );
      if (mounted) Navigator.of(context).pop(trip);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final digitsOnly = [FilteringTextInputFormatter.digitsOnly];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Добавить поездку', style: theme.textTheme.titleLarge),
          Text(
            formatDay(widget.day),
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _TimeButton(
                  label: 'Начало',
                  time: _start,
                  onPressed: () => _pickTime(isStart: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimeButton(
                  label: 'Окончание',
                  time: _end,
                  onPressed: () => _pickTime(isStart: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  inputFormatters: digitsOnly,
                  decoration: const InputDecoration(
                    labelText: 'Сумма, ₸',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _onAmountChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _commission,
                  keyboardType: TextInputType.number,
                  inputFormatters: digitsOnly,
                  decoration: const InputDecoration(
                    labelText: 'Комиссия, ₸',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _changed(() => _commissionEdited = true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<Payment>(
            segments: const [
              ButtonSegment(
                value: Payment.cash,
                label: Text('Наличные'),
                icon: Icon(Icons.payments_outlined),
              ),
              ButtonSegment(
                value: Payment.card,
                label: Text('Карта'),
                icon: Icon(Icons.credit_card),
              ),
            ],
            selected: {_payment},
            onSelectionChanged: (selection) =>
                _changed(() => _payment = selection.first),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: Text(_submitting ? 'Сохраняю…' : 'Добавить'),
          ),
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.time,
    required this.onPressed,
  });

  final String label;
  final TimeOfDay? time;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final time = this.time;
    final text = time == null
        ? '--:--'
        : '${time.hour.toString().padLeft(2, '0')}:'
            '${time.minute.toString().padLeft(2, '0')}';

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.schedule),
      label: Text('$label  $text'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}
