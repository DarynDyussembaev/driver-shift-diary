import { formatMoney } from '../format'
import type { DaySummary } from '../types'

interface Props {
  summary: DaySummary
}

export function Summary({ summary }: Props) {
  return (
    <section className="summary">
      <div className="card card--accent">
        <span className="card__label">На руки</span>
        <span className="card__value">{formatMoney(summary.net)}</span>
      </div>
      <div className="card">
        <span className="card__label">Поездок</span>
        <span className="card__value">{summary.trips_count}</span>
      </div>
      <div className="card">
        <span className="card__label">Выручка</span>
        <span className="card__value">{formatMoney(summary.revenue)}</span>
      </div>
      <div className="card">
        <span className="card__label">Комиссия</span>
        <span className="card__value">{formatMoney(summary.commission)}</span>
      </div>
      <div className="card">
        <span className="card__label">Наличные · {summary.cash.count}</span>
        <span className="card__value">{formatMoney(summary.cash.amount)}</span>
      </div>
      <div className="card">
        <span className="card__label">Карта · {summary.card.count}</span>
        <span className="card__value">{formatMoney(summary.card.amount)}</span>
      </div>
    </section>
  )
}
