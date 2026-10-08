import { durationMinutes, formatMoney, formatTime } from '../format'
import type { Trip } from '../types'

interface Props {
  trips: Trip[]
}

const PAYMENT_LABEL = { cash: 'Наличные', card: 'Карта' } as const

export function TripList({ trips }: Props) {
  if (trips.length === 0) {
    return <p className="empty">За этот день поездок нет.</p>
  }

  return (
    <ul className="trips">
      {trips.map((trip) => (
        <li key={trip.id} className="trip">
          <div className="trip__time">
            <strong>
              {formatTime(trip.start)} – {formatTime(trip.end)}
            </strong>
            <span>{durationMinutes(trip.start, trip.end)} мин</span>
          </div>
          <span className={`badge badge--${trip.payment}`}>{PAYMENT_LABEL[trip.payment]}</span>
          <div className="trip__money">
            <strong>{formatMoney(trip.amount)}</strong>
            <span>комиссия {formatMoney(trip.commission)}</span>
          </div>
        </li>
      ))}
    </ul>
  )
}
