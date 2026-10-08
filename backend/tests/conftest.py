import json

import pytest
from fastapi.testclient import TestClient

from app.main import create_app
from app.storage import TripStore

SEED = [
    {"id": "t1", "start": "2026-10-01T08:10:00+05:00", "end": "2026-10-01T08:32:00+05:00",
     "amount": 2400, "payment": "card", "commission": 360},
    {"id": "t2", "start": "2026-10-01T09:05:00+05:00", "end": "2026-10-01T09:20:00+05:00",
     "amount": 1500, "payment": "cash", "commission": 225},
]


@pytest.fixture
def trips_file(tmp_path):
    path = tmp_path / "trips.json"
    path.write_text(json.dumps(SEED), encoding="utf-8")
    return path


@pytest.fixture
def store(trips_file):
    return TripStore(trips_file)


@pytest.fixture
def client(store):
    return TestClient(create_app(store))


@pytest.fixture
def new_trip():
    return {
        "id": "new-1",
        "start": "2026-10-01T12:00:00+05:00",
        "end": "2026-10-01T12:25:00+05:00",
        "amount": 2000,
        "payment": "cash",
        "commission": 300,
    }
