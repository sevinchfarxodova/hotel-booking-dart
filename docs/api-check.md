# API check: seven requests against PostgreSQL

Start with an empty database (`docker compose down -v`, then `docker compose up -d`) and start the app in a second terminal with `dart run bin/main.dart`. Run these commands from the project folder. Each response body is followed by its HTTP status.

1. Search 12–14 Nov: both rooms are free — **200**

```sh
curl -s -w "\n%{http_code}\n" "http://localhost:5080/rooms/availability?checkIn=2026-11-12&checkOut=2026-11-14"
```
Expected body: `{"checkIn":"2026-11-12","checkOut":"2026-11-14","rooms":[{"number":"R7","type":"Standard"},{"number":"R8","type":"Deluxe"}],"next":null}`

2. Maya books R7 — **201**, `R101`

```sh
curl -s -w "\n%{http_code}\n" -X POST -H "Content-Type: application/json" --data @docs/requests/maya-r7.json http://localhost:5080/reservations
```
Expected body: `{"id":"R101","status":"Confirmed","notificationFailed":false}`

3. Omar requests R7 for an overlapping stay — **409**, `Unavailable`

```sh
curl -s -w "\n%{http_code}\n" -X POST -H "Content-Type: application/json" --data @docs/requests/omar-r7.json http://localhost:5080/reservations
```
Expected body: `{"title":"Unavailable","status":409,"detail":"The room is booked for at least one night of this stay."}`

4. Omar requests R8 for a zero-night stay — **400**, `InvalidDates`

```sh
curl -s -w "\n%{http_code}\n" -X POST -H "Content-Type: application/json" --data @docs/requests/omar-r8.json http://localhost:5080/reservations
```
Expected body: `{"title":"InvalidDates","status":400,"detail":"checkOut must be after checkIn."}`

5. Search again — R8 is free, **200**

```sh
curl -s -w "\n%{http_code}\n" "http://localhost:5080/rooms/availability?checkIn=2026-11-12&checkOut=2026-11-14"
```
Expected body: `{"checkIn":"2026-11-12","checkOut":"2026-11-14","rooms":[{"number":"R8","type":"Deluxe"}],"next":null}`

6. Cancel R101 — **204** with an empty body

```sh
curl -s -w "\n%{http_code}\n" -X DELETE http://localhost:5080/reservations/R101
```

7. Cancel R101 again — **404**, `NotFound`

```sh
curl -s -w "\n%{http_code}\n" -X DELETE http://localhost:5080/reservations/R101
```
Expected body: `{"title":"NotFound","status":404,"detail":"There is no confirmed reservation R101."}`

## Restart proof

Book Maya again; the next id is R102 because the cancelled R101 row remains. Stop the app with Ctrl+C, start it again, then search 12–14 Nov. The answer must still show only R8. Check the durable rows with:

```sh
docker compose exec db psql -U hotel -d hotel -c "SELECT id, guest_name, room, check_in, check_out, status FROM reservations ORDER BY id;"
```
Expected rows: `R101 | Maya | R7 | 2026-11-12 | 2026-11-14 | Cancelled` and `R102 | Maya | R7 | 2026-11-12 | 2026-11-14 | Confirmed`.
