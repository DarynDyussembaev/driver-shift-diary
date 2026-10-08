// Смещение, в котором водитель вводит время новых поездок (Казахстан, UTC+5).
export const TZ_OFFSET = '+05:00'

// Комиссия агрегатора по умолчанию — в примере данных она равна 15% от суммы.
export const DEFAULT_COMMISSION_RATE = 0.15

const moneyFormat = new Intl.NumberFormat('ru-RU')

export function formatMoney(value: number): string {
  return `${moneyFormat.format(value)} ₸`
}

// Время показываем так, как оно записано в поездке, а не в часовом поясе браузера:
// "2026-10-01T08:10:00+05:00" -> "08:10".
export function formatTime(iso: string): string {
  return iso.slice(11, 16)
}

export function durationMinutes(start: string, end: string): number {
  return Math.round((new Date(end).getTime() - new Date(start).getTime()) / 60_000)
}

// Дни — это строки YYYY-MM-DD. Считаем их в UTC, чтобы часовой пояс браузера
// не сдвигал дату при переходе на соседний день.
export function shiftDay(day: string, delta: number): string {
  const date = new Date(`${day}T00:00:00Z`)
  date.setUTCDate(date.getUTCDate() + delta)
  return date.toISOString().slice(0, 10)
}

const dayFormat = new Intl.DateTimeFormat('ru-RU', {
  weekday: 'long',
  day: 'numeric',
  month: 'long',
  year: 'numeric',
  timeZone: 'UTC',
})

export function formatDay(day: string): string {
  return dayFormat.format(new Date(`${day}T00:00:00Z`))
}

const shortDayFormat = new Intl.DateTimeFormat('ru-RU', {
  day: 'numeric',
  month: 'short',
  timeZone: 'UTC',
})

export function formatShortDay(day: string): string {
  return shortDayFormat.format(new Date(`${day}T00:00:00Z`))
}

export function today(): string {
  const now = new Date()
  const month = String(now.getMonth() + 1).padStart(2, '0')
  const date = String(now.getDate()).padStart(2, '0')
  return `${now.getFullYear()}-${month}-${date}`
}
