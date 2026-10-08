import type { DayReport, NewTrip, Trip } from './types'

export class ApiError extends Error {
  constructor(
    message: string,
    public status: number,
  ) {
    super(message)
  }
}

// FastAPI отдаёт detail строкой (наши 409) или списком ошибок валидации (422).
function readDetail(body: unknown): string | null {
  if (typeof body !== 'object' || body === null || !('detail' in body)) return null
  const { detail } = body
  if (typeof detail === 'string') return detail
  if (Array.isArray(detail)) {
    return detail
      .map((item) => (typeof item?.msg === 'string' ? item.msg : null))
      .filter(Boolean)
      .join('; ')
  }
  return null
}

async function request<T>(url: string, init?: RequestInit): Promise<T> {
  let response: Response
  try {
    response = await fetch(url, init)
  } catch {
    throw new ApiError('Сервер недоступен. Проверьте, что бэкенд запущен.', 0)
  }

  const body: unknown = await response.json().catch(() => null)
  if (!response.ok) {
    throw new ApiError(readDetail(body) ?? `Ошибка сервера (${response.status})`, response.status)
  }
  return body as T
}

export function fetchDays(): Promise<string[]> {
  return request('/api/days')
}

export function fetchDay(day: string, signal?: AbortSignal): Promise<DayReport> {
  return request(`/api/days/${day}`, { signal })
}

export function createTrip(trip: NewTrip): Promise<Trip> {
  return request('/api/trips', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(trip),
  })
}
