export type Payment = 'cash' | 'card'

export interface Trip {
  id: string
  start: string
  end: string
  amount: number
  payment: Payment
  commission: number
}

export type NewTrip = Trip

export interface PaymentBreakdown {
  count: number
  amount: number
}

export interface DaySummary {
  trips_count: number
  revenue: number
  commission: number
  net: number
  cash: PaymentBreakdown
  card: PaymentBreakdown
}

export interface DayReport {
  date: string
  summary: DaySummary
  trips: Trip[]
}
