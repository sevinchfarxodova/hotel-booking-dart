# P03 design notes

## Why design before code

Low-level design decides which classes exist, which data and operations each holds, and which objects call one another. The diagrams give both partners a shared plan before they write the booking logic.

## Where the methods live

`Reservation.cancel()` belongs to the reservation because it changes that reservation's own status. `ReservationStore.hasOverlap()` belongs to the store because it needs to inspect all reservations. `DateRange.overlaps()` handles the date comparison. `BookingService.reserve()` coordinates validation, the overlap check, saving, and confirmation.

## Activity traces

| Request | Check-out after check-in? | Confirmed booking shares a night? | End |
| --- | --- | --- | --- |
| Omar, R7, 13–15 November | Yes | Yes, night of the 13th | Unavailable, save nothing |
| Nora, R7, 14–16 November | Yes | No, Maya checks out on the 14th | Save R102, send confirmation, return Accepted R102 |
| Omar, R8, 15–15 November | No | Decision skipped | InvalidDates, save nothing |

## Prediction

Nora should receive `Accepted R102`. Maya checks out on Nora's check-in day, and Omar's rejected request leaves the reservation count unchanged.

## The race

Prediction: R7 will have two confirmed reservations when Maya and Omar both request 12–14 November before either save runs.

Both requests pass the availability check against the empty store, then each resumes and saves its own confirmed reservation. The gap is between `store.hasOverlap()` and `store.save()` inside `BookingService.reserve()`.
