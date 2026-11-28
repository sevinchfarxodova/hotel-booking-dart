# Architecture & Design Notes

# P08 design notes
- Kept `BookingService` completely unaware of Redis and query counters by placing `CountingReservationStore` (decorator) in the unit of work and `AvailabilityCache` in the HTTP API layer (`lib/api.dart`).
- Used a monotonically increasing `availability:version` key in Redis so invalidating all cached date ranges on `POST /reservations` or `DELETE /reservations/{id}` is a single atomic `INCR`.
