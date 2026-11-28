# ADR-002: Cache Room Availability Searches in Redis

- **Status:** Accepted
- **Date:** 2026-11-28

## Context
Room availability searches (`GET /rooms/available`) execute one SQL overlap query per room in PostgreSQL (`N` queries per search). Under peak search load, repeated identical date-range queries waste database CPU and energy even though availability only changes when a reservation is created or cancelled.

## Decision
1. **Cache-aside pattern in Redis:** Cache serialized available room lists under versioned keys `availability:v{version}:{checkIn}:{checkOut}` with a **30-second TTL**.
2. **Event-driven invalidation:** Increment `availability:version` (`INCR`) whenever `POST /reservations` returns `201` or `DELETE /reservations/{id}` returns `204`.
3. **Authoritative writes:** `BookingService` never reads from Redis. All conflict checks (`hasOverlap`) and reservation writes execute directly against PostgreSQL.

## Consequences
- **Positive:** Identical searches drop from `N` PostgreSQL queries per request to `0` after the first cache miss, cutting database load and meeting S1 latency and S6 energy targets.
- **Positive:** Versioned keys provide O(1) invalidation across all cached date ranges without scanning keys (`KEYS`/`SCAN`).
- **Trade-off:** Any booking or cancellation invalidates all cached date ranges globally rather than only overlapping dates, causing a brief burst of cache misses on the next search per date range.
