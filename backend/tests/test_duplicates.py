import json

from app.storage import TripStore


def trips_on_day(client, day="2026-10-01"):
    return client.get(f"/api/days/{day}").json()


def test_first_post_creates_trip(client, new_trip):
    response = client.post("/api/trips", json=new_trip)

    assert response.status_code == 201
    assert response.json()["id"] == "new-1"
    assert trips_on_day(client)["summary"]["trips_count"] == 3


def test_repeated_post_does_not_create_duplicate(client, new_trip):
    first = client.post("/api/trips", json=new_trip)
    second = client.post("/api/trips", json=new_trip)

    assert first.status_code == 201
    assert second.status_code == 200
    assert second.json() == first.json()

    report = trips_on_day(client)
    assert report["summary"]["trips_count"] == 3
    assert report["summary"]["revenue"] == 3900 + 2000


def test_same_trip_without_id_is_not_duplicated(client, new_trip):
    del new_trip["id"]

    first = client.post("/api/trips", json=new_trip)
    second = client.post("/api/trips", json=new_trip)

    assert first.status_code == 201
    assert second.status_code == 200
    assert second.json()["id"] == first.json()["id"]
    assert trips_on_day(client)["summary"]["trips_count"] == 3


def test_same_trip_with_another_id_is_not_duplicated(client, new_trip):
    client.post("/api/trips", json=new_trip)
    response = client.post("/api/trips", json={**new_trip, "id": "new-2"})

    assert response.status_code == 200
    assert response.json()["id"] == "new-1"
    assert trips_on_day(client)["summary"]["trips_count"] == 3


def test_same_moment_in_another_offset_is_the_same_trip(client, new_trip):
    client.post("/api/trips", json=new_trip)
    # 12:00+05:00 и 07:00Z — один и тот же момент.
    in_utc = {**new_trip, "start": "2026-10-01T07:00:00Z", "end": "2026-10-01T07:25:00Z"}
    del in_utc["id"]

    response = client.post("/api/trips", json=in_utc)

    assert response.status_code == 200
    assert trips_on_day(client)["summary"]["trips_count"] == 3


def test_same_id_with_different_data_is_conflict(client, new_trip):
    client.post("/api/trips", json=new_trip)
    response = client.post("/api/trips", json={**new_trip, "amount": 9999})

    assert response.status_code == 409
    report = trips_on_day(client)
    assert report["summary"]["trips_count"] == 3
    assert report["summary"]["revenue"] == 3900 + 2000


def test_resending_seed_trip_is_not_duplicated(client):
    response = client.post("/api/trips", json={
        "id": "t1",
        "start": "2026-10-01T08:10:00+05:00",
        "end": "2026-10-01T08:32:00+05:00",
        "amount": 2400,
        "payment": "card",
        "commission": 360,
    })

    assert response.status_code == 200
    assert trips_on_day(client)["summary"]["trips_count"] == 2


def test_duplicate_is_not_written_to_file(client, new_trip, trips_file):
    client.post("/api/trips", json=new_trip)
    client.post("/api/trips", json=new_trip)

    saved = json.loads(trips_file.read_text(encoding="utf-8"))
    assert [trip["id"] for trip in saved].count("new-1") == 1
    assert len(saved) == 3


def test_dedup_survives_restart(trips_file, new_trip):
    from app.models import TripIn

    TripStore(trips_file).add(TripIn(**new_trip))
    # Новый экземпляр читает файл заново — как после перезапуска сервера.
    _, created = TripStore(trips_file).add(TripIn(**new_trip))

    assert created is False
