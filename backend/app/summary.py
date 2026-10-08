from collections.abc import Iterable

from .models import DaySummary, Trip


def summarize(trips: Iterable[Trip]) -> DaySummary:
    """Сводка по набору поездок. Чистая функция — без доступа к хранилищу."""
    summary = DaySummary()
    for trip in trips:
        summary.trips_count += 1
        summary.revenue += trip.amount
        summary.commission += trip.commission

        bucket = summary.cash if trip.payment == "cash" else summary.card
        bucket.count += 1
        bucket.amount += trip.amount

    summary.net = summary.revenue - summary.commission
    return summary
