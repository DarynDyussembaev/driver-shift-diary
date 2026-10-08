enum Payment { cash, card }

class Trip {
  const Trip({
    required this.id,
    required this.start,
    required this.end,
    required this.amount,
    required this.payment,
    required this.commission,
  });

  final String id;
  // Время храним строкой ISO со смещением, как отдаёт сервер: так его можно
  // показать ровно таким, каким оно записано, а не в часовом поясе телефона.
  final String start;
  final String end;
  final int amount;
  final Payment payment;
  final int commission;

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      start: json['start'] as String,
      end: json['end'] as String,
      amount: json['amount'] as int,
      payment: Payment.values.byName(json['payment'] as String),
      commission: json['commission'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'start': start,
        'end': end,
        'amount': amount,
        'payment': payment.name,
        'commission': commission,
      };

  int get durationMinutes =>
      DateTime.parse(end).difference(DateTime.parse(start)).inMinutes;
}

class PaymentBreakdown {
  const PaymentBreakdown({required this.count, required this.amount});

  final int count;
  final int amount;

  factory PaymentBreakdown.fromJson(Map<String, dynamic> json) {
    return PaymentBreakdown(
      count: json['count'] as int,
      amount: json['amount'] as int,
    );
  }
}

class DaySummary {
  const DaySummary({
    required this.tripsCount,
    required this.revenue,
    required this.commission,
    required this.net,
    required this.cash,
    required this.card,
  });

  final int tripsCount;
  final int revenue;
  final int commission;
  final int net;
  final PaymentBreakdown cash;
  final PaymentBreakdown card;

  factory DaySummary.fromJson(Map<String, dynamic> json) {
    return DaySummary(
      tripsCount: json['trips_count'] as int,
      revenue: json['revenue'] as int,
      commission: json['commission'] as int,
      net: json['net'] as int,
      cash: PaymentBreakdown.fromJson(json['cash'] as Map<String, dynamic>),
      card: PaymentBreakdown.fromJson(json['card'] as Map<String, dynamic>),
    );
  }
}

class DayReport {
  const DayReport({
    required this.date,
    required this.summary,
    required this.trips,
  });

  final String date;
  final DaySummary summary;
  final List<Trip> trips;

  factory DayReport.fromJson(Map<String, dynamic> json) {
    return DayReport(
      date: json['date'] as String,
      summary: DaySummary.fromJson(json['summary'] as Map<String, dynamic>),
      trips: [
        for (final trip in json['trips'] as List<dynamic>)
          Trip.fromJson(trip as Map<String, dynamic>),
      ],
    );
  }
}
