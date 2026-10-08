from app.models import Trip
from app.summary import summarize


def make_trip(id, amount, payment, commission, start="2026-10-01T08:00:00+05:00"):
    return Trip(
        id=id,
        start=start,
        end="2026-10-01T23:00:00+05:00",
        amount=amount,
        payment=payment,
        commission=commission,
    )


def test_summary_of_example_data():
    summary = summarize([
        make_trip("t1", 2400, "card", 360),
        make_trip("t2", 1500, "cash", 225),
    ])

    assert summary.trips_count == 2
    assert summary.revenue == 3900
    assert summary.commission == 585
    assert summary.net == 3315
    assert (summary.card.count, summary.card.amount) == (1, 2400)
    assert (summary.cash.count, summary.cash.amount) == (1, 1500)


def test_summary_of_empty_day_is_all_zeros():
    summary = summarize([])

    assert summary.trips_count == 0
    assert summary.revenue == 0
    assert summary.commission == 0
    assert summary.net == 0
    assert summary.cash.amount == 0
    assert summary.card.amount == 0


def test_breakdown_adds_up_to_revenue():
    summary = summarize([
        make_trip("a", 1000, "cash", 150),
        make_trip("b", 2000, "cash", 300),
        make_trip("c", 3000, "card", 450),
    ])

    assert summary.cash.count == 2
    assert summary.cash.amount == 3000
    assert summary.card.count == 1
    assert summary.card.amount == 3000
    assert summary.cash.amount + summary.card.amount == summary.revenue
    assert summary.cash.count + summary.card.count == summary.trips_count


def test_day_endpoint_returns_trips_and_summary(client):
    body = client.get("/api/days/2026-10-01").json()

    assert body["date"] == "2026-10-01"
    assert [trip["id"] for trip in body["trips"]] == ["t1", "t2"]
    assert body["summary"] == {
        "trips_count": 2,
        "revenue": 3900,
        "commission": 585,
        "net": 3315,
        "cash": {"count": 1, "amount": 1500},
        "card": {"count": 1, "amount": 2400},
    }


def test_day_without_trips_returns_empty_report(client):
    response = client.get("/api/days/2026-12-31")

    assert response.status_code == 200
    assert response.json()["trips"] == []
    assert response.json()["summary"]["trips_count"] == 0


def test_trip_belongs_to_its_local_day_not_utc(client):
    # 00:30 по +05:00 — это ещё 30 сентября по UTC, но для водителя уже 1 октября.
    response = client.post("/api/trips", json={
        "id": "night",
        "start": "2026-10-01T00:30:00+05:00",
        "end": "2026-10-01T00:50:00+05:00",
        "amount": 1000,
        "payment": "cash",
        "commission": 150,
    })
    assert response.status_code == 201

    october_1 = client.get("/api/days/2026-10-01").json()
    september_30 = client.get("/api/days/2026-09-30").json()

    assert "night" in [trip["id"] for trip in october_1["trips"]]
    assert october_1["summary"]["trips_count"] == 3
    assert september_30["trips"] == []


def test_days_endpoint_lists_days_with_trips(client):
    assert client.get("/api/days").json() == ["2026-10-01"]
