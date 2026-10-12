"""Worker: marks new orders as processed every few seconds."""
import logging
import os
import time

import psycopg

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("worker")

DB_DSN = (
    f"host={os.getenv('DB_HOST', 'localhost')} "
    f"port={os.getenv('DB_PORT', '5432')} "
    f"dbname={os.getenv('DB_NAME', 'shop')} "
    f"user={os.getenv('DB_USER', 'shop')} "
    f"password={os.getenv('DB_PASSWORD', 'shop')}"
)
INTERVAL = int(os.getenv("POLL_INTERVAL_SECONDS", "5"))


def process_once() -> int:
    with psycopg.connect(DB_DSN, connect_timeout=3) as conn, conn.cursor() as cur:
        cur.execute("SELECT to_regclass('public.orders')")
        if cur.fetchone()[0] is None:
            return 0  # the API has not created the table yet
        cur.execute("UPDATE orders SET status = 'processed' WHERE status = 'new'")
        conn.commit()
        return cur.rowcount


def main():
    log.info("worker started, polling every %ss", INTERVAL)
    while True:
        try:
            done = process_once()
            if done:
                log.info("processed %d order(s)", done)
        except Exception as exc:  # noqa: BLE001
            log.warning("database not reachable yet: %s", exc)
        time.sleep(INTERVAL)


if __name__ == "__main__":
    main()
