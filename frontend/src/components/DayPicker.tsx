import { formatDay, formatShortDay, shiftDay } from '../format'

interface Props {
  day: string
  daysWithTrips: string[]
  onChange: (day: string) => void
}

export function DayPicker({ day, daysWithTrips, onChange }: Props) {
  return (
    <section className="day-picker">
      <div className="day-picker__row">
        <button type="button" onClick={() => onChange(shiftDay(day, -1))} aria-label="Предыдущий день">
          ←
        </button>
        <input
          type="date"
          value={day}
          // При очистке поля браузер отдаёт пустую строку — её игнорируем.
          onChange={(event) => event.target.value && onChange(event.target.value)}
          aria-label="Дата"
        />
        <button type="button" onClick={() => onChange(shiftDay(day, 1))} aria-label="Следующий день">
          →
        </button>
      </div>

      <h2 className="day-picker__title">{formatDay(day)}</h2>

      {daysWithTrips.length > 0 && (
        <div className="day-picker__chips">
          {daysWithTrips.map((item) => (
            <button
              type="button"
              key={item}
              className={item === day ? 'chip chip--active' : 'chip'}
              onClick={() => onChange(item)}
            >
              {formatShortDay(item)}
            </button>
          ))}
        </div>
      )}
    </section>
  )
}
