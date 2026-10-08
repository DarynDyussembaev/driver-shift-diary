import { useCallback, useEffect, useState } from 'react'
import { ApiError, fetchDay, fetchDays } from './api'
import { DayPicker } from './components/DayPicker'
import { Summary } from './components/Summary'
import { TripForm } from './components/TripForm'
import { TripList } from './components/TripList'
import { today } from './format'
import type { DayReport } from './types'

export function App() {
  const [day, setDay] = useState<string | null>(null)
  const [daysWithTrips, setDaysWithTrips] = useState<string[]>([])
  const [report, setReport] = useState<DayReport | null>(null)
  const [error, setError] = useState<string | null>(null)
  // Меняем, чтобы перезапросить текущий день после добавления поездки.
  const [reloadKey, setReloadKey] = useState(0)

  const loadDays = useCallback(async () => {
    const days = await fetchDays()
    setDaysWithTrips(days)
    return days
  }, [])

  // При старте открываем последний день, за который есть поездки.
  useEffect(() => {
    loadDays()
      .then((days) => setDay(days.at(-1) ?? today()))
      .catch(() => setDay(today()))
  }, [loadDays])

  useEffect(() => {
    if (!day) return
    // Если день переключили быстрее, чем пришёл ответ, старый запрос отменяем,
    // иначе он может прийти позже и затереть данные нового дня.
    const controller = new AbortController()
    setError(null)

    fetchDay(day, controller.signal)
      .then(setReport)
      .catch((err) => {
        if (controller.signal.aborted) return
        setReport(null)
        setError(err instanceof ApiError ? err.message : 'Не удалось загрузить данные')
      })

    return () => controller.abort()
  }, [day, reloadKey])

  function handleCreated() {
    setReloadKey((key) => key + 1)
    loadDays().catch(() => {})
  }

  if (!day) {
    return <p className="empty">Загрузка…</p>
  }

  const isStale = report !== null && report.date !== day

  return (
    <main className="app">
      <h1>Дневник смен водителя</h1>

      <DayPicker day={day} daysWithTrips={daysWithTrips} onChange={setDay} />

      {error && <p className="error">{error}</p>}

      {report && (
        <div className={isStale ? 'report report--stale' : 'report'}>
          <Summary summary={report.summary} />
          <TripList trips={report.trips} />
        </div>
      )}

      <TripForm day={day} onCreated={handleCreated} />
    </main>
  )
}
