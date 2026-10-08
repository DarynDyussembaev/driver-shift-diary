import os
from datetime import date
from pathlib import Path

from fastapi import FastAPI, HTTPException, Response, status
from fastapi.middleware.cors import CORSMiddleware

from .models import DayReport, Trip, TripIn
from .storage import TripConflict, TripStore
from .summary import summarize

DATA_DIR = Path(__file__).resolve().parent.parent / "data"
# trips.json — исходные данные из репозитория, trips.local.json — рабочая копия,
# в которую пишет сервер (в .gitignore).
SEED_FILE = DATA_DIR / "trips.json"
DEFAULT_FILE = DATA_DIR / "trips.local.json"


def create_app(store: TripStore | None = None) -> FastAPI:
    if store is None:
        store = TripStore(Path(os.environ.get("TRIPS_FILE", DEFAULT_FILE)), seed=SEED_FILE)

    app = FastAPI(title="Дневник смен водителя")

    # Нужен только для Flutter-клиента в браузере при локальной разработке:
    # он открывается на своём порту и ходит в API напрямую, без прокси.
    app.add_middleware(
        CORSMiddleware,
        allow_origin_regex=r"http://(localhost|127\.0\.0\.1)(:\d+)?",
        allow_methods=["GET", "POST"],
        allow_headers=["Content-Type"],
    )

    @app.get("/api/days", response_model=list[date])
    def list_days() -> list[date]:
        """Дни, за которые есть поездки."""
        return store.days()

    @app.get("/api/days/{day}", response_model=DayReport)
    def get_day(day: date) -> DayReport:
        """Поездки и сводка за день. Для дня без поездок — пустой список и нули."""
        trips = store.by_day(day)
        return DayReport(date=day, summary=summarize(trips), trips=trips)

    @app.post("/api/trips", response_model=Trip, status_code=status.HTTP_201_CREATED)
    def add_trip(data: TripIn, response: Response) -> Trip:
        try:
            trip, created = store.add(data)
        except TripConflict:
            raise HTTPException(
                status.HTTP_409_CONFLICT,
                detail=f"Поездка с id '{data.id}' уже существует с другими данными",
            )
        if not created:
            # Повторная отправка: отдаём сохранённую поездку, но не 201.
            response.status_code = status.HTTP_200_OK
        return trip

    return app


app = create_app()
