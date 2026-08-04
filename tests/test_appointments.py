def test_create_and_list_appointment(client):
    payload = {
        "customer_name": "Jane Doe",
        "provider_name": "Dr. Smith",
        "scheduled_at": "2026-09-01T10:00:00",
        "notes": "First visit",
    }
    create_resp = client.post("/appointments", json=payload)
    assert create_resp.status_code == 201
    created = create_resp.json()
    assert created["customer_name"] == "Jane Doe"
    assert "id" in created

    list_resp = client.get("/appointments")
    assert list_resp.status_code == 200
    appointments = list_resp.json()
    assert len(appointments) == 1
    assert appointments[0]["provider_name"] == "Dr. Smith"
