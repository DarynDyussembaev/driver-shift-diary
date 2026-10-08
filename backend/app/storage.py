import json
import os
import shutil
import threading
import uuid
from datetime import date
from pathlib import Path

from pydantic import TypeAdapter

from .models import Trip, TripIn

_trips_adapter = TypeAdapter(list[Trip])


class TripConflict(Exception):
    """Поездка с таким id уже есть, но с другими данными."""


class TripStore:
    """Хранилище поездок в JSON-файле.

    Файл читается один раз при старте, дальше работаем с копией в памяти
    и переписываем файл целиком при каждом добавлении.
    """

    def __init__(self, path: Path, seed: Path | None = None) -> None:
        self._path = Path(path)
        self._lock = threading.Lock()

        if not self._path.exists() and seed is not None and Path(seed).exists():
            self._path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(seed, self._path)

        self._trips: dict[str, Trip] = {}
        if self._path.exists():
            raw = self._path.read_text(encoding="utf-8")
            for trip in _trips_adapter.validate_json(raw or "[]"):
                self._trips[trip.id] = trip

    def days(self) -> list[date]:
        with self._lock:
            return sorted({trip.day for trip in self._trips.values()})

    def by_day(self, day: date) -> list[Trip]:
        with self._lock:
            trips = [trip for trip in self._trips.values() if trip.day == day]
        return sorted(trips, key=lambda trip: trip.start)

    def add(self, data: TripIn) -> tuple[Trip, bool]:
        """Добавляет поездку. Возвращает (поездка, создана_ли).

        Повтор той же поездки не создаёт дубль:
        - тот же id с теми же данными — возвращаем уже сохранённую;
        - тот же id с другими данными — TripConflict;
        - id другой или не передан, но данные совпадают полностью — тоже дубль.
        """
        # Проверка и запись под одним локом, иначе два параллельных запроса
        # с одинаковой поездкой оба пройдут проверку.
        with self._lock:
            if data.id is not None and data.id in self._trips:
                existing = self._trips[data.id]
                if existing.same_content(data):
                    return existing, False
                raise TripConflict(data.id)

            for existing in self._trips.values():
                if existing.same_content(data):
                    return existing, False

            trip = Trip(**data.model_dump(exclude={"id"}), id=data.id or uuid.uuid4().hex)
            self._trips[trip.id] = trip
            try:
                self._save()
            except Exception:
                del self._trips[trip.id]
                raise
            return trip, True

    def _save(self) -> None:
        trips = sorted(self._trips.values(), key=lambda trip: trip.start)
        payload = [trip.model_dump(mode="json") for trip in trips]

        # Пишем во временный файл и подменяем: при падении посреди записи
        # основной файл не останется обрезанным.
        self._path.parent.mkdir(parents=True, exist_ok=True)
        tmp = self._path.with_name(self._path.name + ".tmp")
        tmp.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
        os.replace(tmp, self._path)
