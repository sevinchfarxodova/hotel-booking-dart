# Capacity estimate: hotel booking app

These are estimates from assumptions, not measurements. P08 measures the real app.

## Assumptions

| Assumption | Value | Reason |
| --- | ---: | --- |
| Visitors per day | 1,440 | about one visitor a minute |
| Searches per visitor | 20 | guests try several dates |
| Bookings per day | 20 | 40 rooms, most stays are two nights |
| Peak factor | 10 | Friday evenings and holiday sales |
| Queries per search | 40 | availability asks once per room |

## Results

| Number | Calculation | Result |
| --- | --- | ---: |
| Searches, average | 1,440 × 20 ÷ 86,400 seconds | 0.33 per second |
| Searches, peak | 0.33 × 10 | 3.33 per second = 200 per minute (S1) |
| Database queries, peak | 3.33 × 40 rooms | 133 per second |
| Reservation storage | 20 × 365 × 600 bytes | 4.38 MB per year |
| Bandwidth, peak | 3.33 × 2 KB; 0.17 × 2 MB | 6.67 KB/s search JSON; 333 KB/s photos |

## To measure in P08

- p95 latency for 1,000 availability searches for 12–14 November; target at or below 1 second (S1).
- Database queries per search, for example through a temporary `/stats` endpoint.

These calculations are planning estimates. They do not claim the current app meets the capacity target.
