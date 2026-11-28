# L04 notes carried into P07

## Peak estimate

1,440 visitors/day × 20 searches each = 28,800 searches/day.
28,800 ÷ 86,400 seconds = 0.33 searches/second on average.
0.33 × a peak factor of 10 = 3.33 searches/second, or about 200/minute (S1).
At 40 rooms and one availability query per room, peak load is about 133 database questions/second.

## API decisions

- Use a modular monolith and add the HTTP API outside the four business modules.
- Use PostgreSQL for durable reservations and room catalog data.
- Keep the booking rule in Reservations; translate its result into HTTP at the API edge.
- P08 should measure real p95 search latency and queries per search before a cache is added.
