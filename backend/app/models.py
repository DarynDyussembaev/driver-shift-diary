from datetime import date
from typing import Literal

from pydantic import AwareDatetime, BaseModel, Field, model_validator

Payment = Literal["cash", "card"]


class TripIn(BaseModel):
    """Поездка в том виде, в котором её присылает клиент."""

    # id — ключ идемпотентности: клиент генерирует его один раз и повторяет при ретраях.
    id: str | None = Field(default=None, min_length=1, max_length=64)
    # Время обязательно со смещением: без него нельзя понять, к какому дню относится поездка.
    start: AwareDatetime
    end: AwareDatetime
    # Деньги храним целыми числами (тенге), чтобы не ловить ошибки округления float.
    amount: int = Field(gt=0)
    payment: Payment
    commission: int = Field(ge=0)

    @model_validator(mode="after")
    def check_consistency(self) -> "TripIn":
        if self.end <= self.start:
            raise ValueError("end must be later than start")
        if self.commission > self.amount:
            raise ValueError("commission must not exceed amount")
        return self


class Trip(TripIn):
    id: str

    @property
    def day(self) -> date:
        """День смены — локальная дата начала поездки (в её собственном смещении)."""
        return self.start.date()

    def same_content(self, other: TripIn) -> bool:
        # datetime сравниваются как моменты времени, так что 08:10+05:00 == 03:10Z.
        return (
            self.start == other.start
            and self.end == other.end
            and self.amount == other.amount
            and self.payment == other.payment
            and self.commission == other.commission
        )


class PaymentBreakdown(BaseModel):
    count: int = 0
    amount: int = 0


class DaySummary(BaseModel):
    trips_count: int = 0
    revenue: int = 0
    commission: int = 0
    # «На руки» = выручка минус комиссия.
    net: int = 0
    cash: PaymentBreakdown = Field(default_factory=PaymentBreakdown)
    card: PaymentBreakdown = Field(default_factory=PaymentBreakdown)


class DayReport(BaseModel):
    date: date
    summary: DaySummary
    trips: list[Trip]
