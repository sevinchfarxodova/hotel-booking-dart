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

# P04 design notes

## Refactoring

Refactoring changes the structure of the code while preserving its observable behaviour. The six original booking checks, all nine demo lines, and the deliberate double booking in race mode are the baseline. R6 adds a separately tested outcome for failed delivery after the refactoring.

## What our code breaks

- **Single responsibility.** The P03 file mixes the entry point, booking policy, data storage, and delivery. P04 puts these responsibilities in separate files.
- **Open/closed.** The P03 service refers to email directly. A new channel would require editing the service. P04 adds SMS through the notification interface.
- **Liskov substitution.** Email, SMS, and the fake sender can each stand in for the notification port. The service handles a delivery exception after saving.
- **Interface segregation.** The store exposes reservation operations and the sender exposes one confirmation operation.
- **Dependency inversion.** The service takes storage and notification interfaces. The entry point chooses the concrete adapters.

## Proof

- Tests: Eight cases are defined, including the six baseline checks, R6, and SMS. Run `dart test` to verify.
- Demo: The nine print statements and their inputs match P03. Run `dart run bin/main.dart` and compare with the README.
- Race: The check and save still have an asynchronous gap. Run `dart run bin/main.dart --race` and expect two confirmed reservations.

The Dart SDK was unavailable during packaging, so these runtime results remain to be verified.

# P06 design notes

## Before

- Behaviour tests: the eight P04 checks are the safety net; P06 adds three architecture checks.
- Demo: preserve the same nine output lines as P04.
- Race: preserve the deliberate two-booking race; P09 is where it is fixed.

## Modules

| Module | Public contract | Internal implementation |
| --- | --- | --- |
| Rooms | `Room`, `RoomCatalog` | `InMemoryRoomCatalog` |
| Reservations | `BookingService`, `BookingResult`, `DateRange`, `Guest`, `Reservation`, `ReservationStatus`, `ReservationStore` | `InMemoryReservationStore` |
| Payments | `PaymentStatus`, `PaymentService` | `SimulatedPaymentService` |
| Notifications | `Confirmation`, `NotificationSender` | `EmailNotificationSender`, `SmsNotificationSender` |

`Confirmation` carries only reservation ID, guest email, room number, check-in and check-out. Notifications does not import the Reservations model, so the two modules do not form a dependency cycle.

## Architecture rules

1. Reservations may use other modules' public contracts, but never their `src/` implementation files.
2. Rooms has no dependency on Reservations, Payments or Notifications.
3. Payments and Notifications do not depend on Reservations.

`test/architecture_test.dart` checks the imports in `lib/`. The three tests run with the eight behavior tests using `dart test`.

## Broken on purpose

To prove the first guard works, temporarily add `import 'package:hotel_booking/notifications/src/email.dart';` to `lib/reservations/src/booking.dart`, run `dart test`, and confirm the Reservations boundary test fails with the offending import. Remove that line and run `dart test` again. Do not keep the forbidden import.

## After

- Behaviour checks: the same eight P04 tests, plus three architecture checks (11 total).
- Demo: the same nine P04 output lines.
- Race: still demonstrates two confirmed bookings for R7 because the availability check and save are not yet atomic.

The module folders make the four P05 contexts visible in code. A single Dart program still builds and runs; `bin/main.dart` is the composition root that constructs internal adapters.

