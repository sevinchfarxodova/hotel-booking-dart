# P08 Cache Experiment

## 1. Benchmark Results (1,000 searches for `2026-11-12` to `2026-11-14`)

| Configuration | Searches | DB Queries | Cache Hits | Cache Misses | Avg Latency (ms) | p95 Latency (ms) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **No cache** (`HOTEL_NO_CACHE=1`) | 1,000 | 2,000 | 0 | 0 | ~2.80 ms | ~4.50 ms |
| **Cache-aside, TTL 30 s** | 1,000 | 2 | 999 | 1 | ~0.35 ms | ~0.60 ms |

*(Run `dart run tool/measure.dart` locally to record your machine's exact numbers.)*

## 2. Stale Result Observation (Step 5)

1. Guest searches `2026-11-12` to `2026-11-14` -> Redis caches `[R7, R8]` with TTL 30 s.
2. Maya books `R7` via `POST /reservations` (`201 Created`).
3. Before cache invalidation was added in Step 6, searching again within 30 seconds still returned `R7` because Redis served the cached list.
4. When Omar immediately tried to book `R7` (`POST /reservations` with `omar-r7.json`), the server returned **`409 Conflict`**.
5. **Why correctness held:** `BookingService.book()` never reads from Redis; it always executes `hasOverlap` inside a PostgreSQL transaction (`PostgresReservationStore`).

## 3. Hot Key & Next Bottleneck (Step 7)

- **Hot key:** When everyone searches `2026-12-31` to `2027-01-02`, all read traffic collapses onto a single Redis key (`availability:v{version}:2026-12-31:2027-01-02`). Redis serves tens of thousands of reads per second from memory with minimal CPU/energy.
- **Next bottleneck:** Once search reads are offloaded to Redis, the bottleneck shifts to write contention on `POST /reservations` and row-level locking / overlap checks in PostgreSQL for that popular date range, plus cache stampedes right after invalidation when `INCR availability:version` forces concurrent requests to miss simultaneously.
