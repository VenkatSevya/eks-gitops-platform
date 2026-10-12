from fastapi.testclient import TestClient

import app as api

client = TestClient(api.app)


def test_health_does_not_need_database():
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}


def test_metrics_are_exposed():
    client.get("/health")
    resp = client.get("/metrics")
    assert resp.status_code == 200
    assert "http_requests_total" in resp.text


def test_ready_reports_503_without_database():
    resp = client.get("/ready")
    assert resp.status_code == 503


def test_injected_failure(monkeypatch):
    monkeypatch.setattr(api, "FAILURE_RATE", 1.0)
    resp = client.get("/orders")
    assert resp.status_code == 500
