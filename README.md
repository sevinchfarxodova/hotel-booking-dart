# P08 · Hotel Booking (Dart + PostgreSQL + Redis)

Complete P08 implementation featuring cache-aside room availability in Redis, runtime search/database/cache metrics (`GET /stats`), event-driven cache invalidation, and a 1,000-request benchmark tool.

## Project Structure

```text
hotel-booking/
├── .vscode/
│   ├── launch.json          # Debug/Run configurations for API server & benchmark tool
│   └── tasks.json           # VS Code tasks for Docker, tests, and benchmarks
├── bin/
│   └── main.dart            # Application entrypoint & dependency wiring
├── db/
│   └── init.sql             # PostgreSQL schema and seed rooms (R7, R8)
├── docs/
│   ├── requests/            # Sample JSON payloads (maya-r7, omar-r7, omar-r8)
│   ├── adr-002-cache-availability.md
│   ├── cache-experiment.md
│   ├── capacity.md
│   ├── design-notes.md
│   └── openapi.yaml
├── lib/
│   ├── api.dart             # HTTP endpoints, Stats, CountingReservationStore, invalidation
│   ├── api_cache.dart       # RedisAvailabilityCache & InMemoryAvailabilityCache
│   ├── notifications/       # Email & SMS notification senders
│   ├── payments/            # Simulated payment service
│   ├── reservations/        # BookingService, domain models, InMemory & Postgres stores
│   └── rooms/               # Room models & catalogs
├── test/
│   ├── api_test.dart        # GET /stats & Redis cache hit/miss/invalidation tests
│   ├── architecture_test.dart
│   └── booking_service_test.dart
├── tool/
│   └── measure.dart         # 1,000-search latency & /stats benchmark runner
├── docker-compose.yml       # PostgreSQL 16 + Redis 7 services
├── pubspec.yaml
└── README.md
```

## Running the Experiments

### Step 1 · Baseline Measurement (No Cache)
Start the server without Redis caching (`F5` -> **Run API (No Cache - Step 1)** or in Terminal 1):
```bash
HOTEL_NO_CACHE=1 dart run bin/main.dart
```
In Terminal 2, run the 1,000-search measurement tool:
```bash
dart run tool/measure.dart
```
Expected result: `searches=1000, databaseQueries=2000, cacheHits=0, cacheMisses=0`.

### Step 4 · Cached Measurement (Redis Cache-Aside, TTL 30s)
Restart the server with Redis enabled (`F5` -> **Run API (With Redis Cache)** or in Terminal 1):
```bash
dart run bin/main.dart
```
In Terminal 2, run the measurement tool again:
```bash
dart run tool/measure.dart
```
Expected result: `searches=1000, databaseQueries=2, cacheHits=999, cacheMisses=1`.

### Manual Curl Checks (Step 5 & Step 6)
```bash
# Search available rooms
curl "http://localhost:5080/rooms/available?checkIn=2026-11-12&checkOut=2026-11-14"

# Book R7 for Maya (invalidates cache)
curl -X POST http://localhost:5080/reservations -H "Content-Type: application/json" -d @docs/requests/maya-r7.json

# Attempt to book R7 for Omar (returns 409 Conflict from PostgreSQL)
curl -X POST http://localhost:5080/reservations -H "Content-Type: application/json" -d @docs/requests/omar-r7.json

# Check runtime stats
curl http://localhost:5080/stats
```
