import pytest


@pytest.mark.parametrize("amount", [0, -100])
def test_amount_must_be_positive(client, new_trip, amount):
    response = client.post("/api/trips", json={**new_trip, "amount": amount})

    assert response.status_code == 422


def test_end_must_be_later_than_start(client, new_trip):
    response = client.post("/api/trips", json={
        **new_trip,
        "start": "2026-10-01T12:25:00+05:00",
        "end": "2026-10-01T12:00:00+05:00",
    })

    assert response.status_code == 422


def test_end_equal_to_start_is_rejected(client, new_trip):
    response = client.post("/api/trips", json={**new_trip, "end": new_trip["start"]})

    assert response.status_code == 422


def test_end_is_compared_as_moment_not_as_string(client, new_trip):
    # По строке 13:00 > 12:00, но 13:00+09:00 — это 09:00 по +05:00, то есть раньше начала.
    response = client.post("/api/trips", json={
        **new_trip,
        "start": "2026-10-01T12:00:00+05:00",
        "end": "2026-10-01T13:00:00+09:00",
    })

    assert response.status_code == 422


def test_time_without_offset_is_rejected(client, new_trip):
    response = client.post("/api/trips", json={
        **new_trip,
        "start": "2026-10-01T12:00:00",
        "end": "2026-10-01T12:25:00",
    })

    assert response.status_code == 422


def test_unknown_payment_is_rejected(client, new_trip):
    response = client.post("/api/trips", json={**new_trip, "payment": "crypto"})

    assert response.status_code == 422


def test_commission_cannot_exceed_amount(client, new_trip):
    response = client.post("/api/trips", json={**new_trip, "commission": 2001})

    assert response.status_code == 422


def test_invalid_trip_is_not_saved(client, new_trip):
    client.post("/api/trips", json={**new_trip, "amount": 0})

    assert client.get("/api/days/2026-10-01").json()["summary"]["trips_count"] == 2


def test_invalid_date_in_url_is_rejected(client):
    assert client.get("/api/days/not-a-date").status_code == 422
