"""Orders API: a small FastAPI service backed by PostgreSQL."""
import os
import random

import psycopg
from fastapi import FastAPI, HTTPException
from prometheus_fastapi_instrumentator import Instrumentator
from pydantic import BaseModel

DB_DSN = (
    f"host={os.getenv('DB_HOST', 'localhost')} "
    f"port={os.getenv('DB_PORT', '5432')} "
    f"dbname={os.getenv('DB_NAME', 'shop')} "
    f"user={os.getenv('DB_USER', 'shop')} "
    f"password={os.getenv('DB_PASSWORD', 'shop')}"
)
# Fraction of /orders requests that fail on purpose (0.0 = never).
# Used to trigger the SLO alert for the root-cause analysis exercise.
FAILURE_RATE = float(os.getenv("FAILURE_RATE", "0"))

app = FastAPI(title="orders-api")
Instrumentator().instrument(app).expose(app, endpoint="/metrics", include_in_schema=False)

_schema_ready = False


class OrderIn(BaseModel):
    item: str
    quantity: int = 1


def get_conn():
    global _schema_ready
    conn = psycopg.connect(DB_DSN, connect_timeout=3)
    if not _schema_ready:
        with conn.cursor() as cur:
            cur.execute(
                """CREATE TABLE IF NOT EXISTS orders (
                       id SERIAL PRIMARY KEY,
                       item TEXT NOT NULL,
                       quantity INT NOT NULL,
                       status TEXT NOT NULL DEFAULT 'new',
                       created_at TIMESTAMPTZ NOT NULL DEFAULT now())"""
            )
        conn.commit()
        _schema_ready = True
    return conn


def maybe_fail():
    if FAILURE_RATE > 0 and random.random() < FAILURE_RATE:
        raise HTTPException(status_code=500, detail="injected failure")


@app.get("/health")
def health():
    """Liveness: the process is up. Does not touch the database."""
    return {"status": "ok"}


@app.get("/ready")
def ready():
    """Readiness: the database is reachable."""
    try:
        with get_conn() as conn, conn.cursor() as cur:
            cur.execute("SELECT 1")
        return {"status": "ready"}
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=503, detail=f"database unavailable: {exc}")


@app.get("/orders")
def list_orders():
    maybe_fail()
    with get_conn() as conn, conn.cursor() as cur:
        cur.execute("SELECT id, item, quantity, status FROM orders ORDER BY id DESC LIMIT 50")
        rows = cur.fetchall()
    return [{"id": r[0], "item": r[1], "quantity": r[2], "status": r[3]} for r in rows]


@app.post("/orders", status_code=201)
def create_order(order: OrderIn):
    maybe_fail()
    if order.quantity < 1:
        raise HTTPException(status_code=422, detail="quantity must be at least 1")
    with get_conn() as conn, conn.cursor() as cur:
        cur.execute(
            "INSERT INTO orders (item, quantity) VALUES (%s, %s) RETURNING id",
            (order.item, order.quantity),
        )
        new_id = cur.fetchone()[0]
        conn.commit()
    return {"id": new_id, "item": order.item, "quantity": order.quantity, "status": "new"}
