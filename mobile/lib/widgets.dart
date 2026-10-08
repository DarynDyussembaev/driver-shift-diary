import 'package:flutter/material.dart';

import 'format.dart';
import 'models.dart';

class SummaryView extends StatelessWidget {
  const SummaryView({super.key, required this.summary});

  final DaySummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        _StatCard(
          label: 'На руки',
          value: formatMoney(summary.net),
          background: scheme.primary,
          foreground: scheme.onPrimary,
          large: true,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _StatCard(label: 'Поездок', value: '${summary.tripsCount}'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                label: 'Выручка',
                value: formatMoney(summary.revenue),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                label: 'Комиссия',
                value: formatMoney(summary.commission),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Наличные · ${summary.cash.count}',
                value: formatMoney(summary.cash.amount),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                label: 'Карта · ${summary.card.count}',
                value: formatMoney(summary.card.amount),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.background,
    this.foreground,
    this.large = false,
  });

  final String label;
  final String value;
  final Color? background;
  final Color? foreground;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final valueStyle =
        large ? theme.textTheme.headlineMedium : theme.textTheme.titleMedium;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background ?? scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: foreground ?? scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          // Длинная сумма в узкой карточке сжимается, а не обрезается.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: valueStyle?.copyWith(
                color: foreground ?? scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TripTile extends StatelessWidget {
  const TripTile({super.key, required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isCash = trip.payment == Payment.cash;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            isCash ? scheme.tertiaryContainer : scheme.secondaryContainer,
        foregroundColor:
            isCash ? scheme.onTertiaryContainer : scheme.onSecondaryContainer,
        child: Icon(isCash ? Icons.payments_outlined : Icons.credit_card),
      ),
      title: Text('${formatTime(trip.start)} – ${formatTime(trip.end)}'),
      subtitle: Text(
        '${trip.durationMinutes} мин · ${isCash ? 'Наличные' : 'Карта'}',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatMoney(trip.amount),
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            'комиссия ${formatMoney(trip.commission)}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
