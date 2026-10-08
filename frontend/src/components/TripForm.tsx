import { useState, type FormEvent } from 'react'
import { ApiError, createTrip } from '../api'
import { DEFAULT_COMMISSION_RATE, TZ_OFFSET } from '../format'
import type { Payment, Trip } from '../types'

interface Props {
  day: string
  onCreated: (trip: Trip) => void
}

interface FormState {
  start: string
  end: string
  amount: string
  payment: Payment
  // null — комиссию не трогали руками, считаем её от суммы.
  commission: string | null
}

const EMPTY: FormState = { start: '', end: '', amount: '', payment: 'cash', commission: null }

function validate(form: FormState, commission: number): string | null {
  if (!form.start || !form.end) return 'Укажите время начала и окончания'
  // Оба времени в одном дне и в формате ЧЧ:ММ, поэтому сравнение строк корректно.
  if (form.end <= form.start) return 'Окончание должно быть позже начала'
  const amount = Number(form.amount)
  if (!Number.isInteger(amount) || amount <= 0) return 'Сумма должна быть целым числом больше нуля'
  if (!Number.isInteger(commission) || commission < 0) return 'Комиссия не может быть отрицательной'
  if (commission > amount) return 'Комиссия не может быть больше суммы'
  return null
}

export function TripForm({ day, onCreated }: Props) {
  const [form, setForm] = useState<FormState>(EMPTY)
  // Ключ идемпотентности. Он живёт, пока данные формы не менялись: если запрос
  // оборвался и пользователь нажал «Добавить» ещё раз, уйдёт тот же id
  // и сервер не создаст вторую поездку.
  const [tripId, setTripId] = useState(() => crypto.randomUUID())
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const commission =
    form.commission === null
      ? Math.round(Number(form.amount || 0) * DEFAULT_COMMISSION_RATE)
      : Number(form.commission)

  function update(patch: Partial<FormState>) {
    setForm((current) => ({ ...current, ...patch }))
    // Данные изменились — это уже другая поездка, ей нужен новый id.
    setTripId(crypto.randomUUID())
    setError(null)
  }

  async function handleSubmit(event: FormEvent) {
    event.preventDefault()
    if (submitting) return

    const problem = validate(form, commission)
    if (problem) {
      setError(problem)
      return
    }

    setSubmitting(true)
    setError(null)
    try {
      const trip = await createTrip({
        id: tripId,
        start: `${day}T${form.start}:00${TZ_OFFSET}`,
        end: `${day}T${form.end}:00${TZ_OFFSET}`,
        amount: Number(form.amount),
        payment: form.payment,
        commission,
      })
      setForm(EMPTY)
      setTripId(crypto.randomUUID())
      onCreated(trip)
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'Не удалось добавить поездку')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <form className="trip-form" onSubmit={handleSubmit} noValidate>
      <h3>Добавить поездку</h3>

      <div className="trip-form__grid">
        <label>
          Начало
          <input type="time" value={form.start} onChange={(e) => update({ start: e.target.value })} />
        </label>
        <label>
          Окончание
          <input type="time" value={form.end} onChange={(e) => update({ end: e.target.value })} />
        </label>
        <label>
          Сумма, ₸
          <input
            type="number"
            inputMode="numeric"
            min="1"
            step="1"
            value={form.amount}
            onChange={(e) => update({ amount: e.target.value })}
          />
        </label>
        <label>
          Комиссия, ₸
          <input
            type="number"
            inputMode="numeric"
            min="0"
            step="1"
            value={form.commission ?? (form.amount ? String(commission) : '')}
            onChange={(e) => update({ commission: e.target.value })}
          />
        </label>
        <label>
          Оплата
          <select value={form.payment} onChange={(e) => update({ payment: e.target.value as Payment })}>
            <option value="cash">Наличные</option>
            <option value="card">Карта</option>
          </select>
        </label>
      </div>

      {error && <p className="error">{error}</p>}

      <button type="submit" className="primary" disabled={submitting}>
        {submitting ? 'Сохраняю…' : 'Добавить'}
      </button>
    </form>
  )
}
