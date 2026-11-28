# P07 · Hotel booking in Dart

P07 extends the P06 modular monolith with a Shelf HTTP API and PostgreSQL persistence. The app exposes room availability, reservation creation and cancellation at `http://localhost:5080`; it serves its contract from `/openapi.yaml`. The booking rule stays in Reservations. The intentional race remains until P09.

## Requirements

- Dart 3 or later
- Docker Desktop with the Docker engine running
- Internet for the first dependency and PostgreSQL image downloads

## Run

```sh
dart pub get
dart analyze
dart test
docker compose up -d
docker compose ps
docker compose exec db psql -U hotel -d hotel -c "SELECT * FROM rooms;"
dart run bin/main.dart --demo
dart run bin/main.dart --race
dart run bin/main.dart
```

The API starts on `http://localhost:5080`. Use `--demo` and `--race` to run the P06 console demonstrations without PostgreSQL. The automated tests comprise 8 booking behavior tests, 3 architecture tests and 4 API tests (15 total); the API tests use in-memory storage. The PostgreSQL request and restart checks are documented in [docs/api-check.md](docs/api-check.md).

If port 5432 is busy, use the same alternate port for Docker and the Dart app:

```sh
export HOTEL_DB_PORT=15432
docker compose up -d
HOTEL_DB_PORT=15432 dart run bin/main.dart
```

## Project notes

- [Capacity estimate](docs/capacity.md)
- [API contract](docs/openapi.yaml)
- [API request and restart check](docs/api-check.md)
- [L04 assumptions and decisions](docs/l04-notes.md)
- [Design notes](docs/design-notes.md)
- [ADR-001](docs/adr-001-modular-monolith.md)
- [Editable diagrams](docs/diagrams.drawio)

Stop PostgreSQL and preserve its data with `docker compose down`. Use `docker compose down -v` only when you want to remove the data volume and reset the database.
