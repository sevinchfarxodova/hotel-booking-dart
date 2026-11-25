# Requirements: hotel booking app, version 1

## R1 · Search

A guest or receptionist can list the rooms that are free for given dates.

Check: Empty hotel, 12–14 November → R7, R8.

Proof: `Free rooms 12-14 Nov: R7, R8`

## R2 · Book

A guest or receptionist can book a free room. The app answers with a reservation id.

Check: Maya books R7 for 12–14 November → Accepted R101.

Proof: `Maya books R7 12-14 Nov: Accepted R101`

## R3 · No clash

A room never has two Confirmed bookings on the same night. Check-out must be after check-in. P03 enforces the rule in sequential requests. The race exercise exposes the remaining concurrency bug.

Check: Omar asks for R7 on 13–15 → Unavailable. 15–15 → InvalidDates.

Proof: `Omar books R7 13-15 Nov: Unavailable` and `Omar books R8 15-15 Nov: InvalidDates`.

More examples:

| Request | Result |
| --- | --- |
| Maya books R7 for 12–14 November | Confirmed for nights 12 and 13 |
| Omar asks for R7 for 13–15 November | Unavailable because night 13 is shared |
| Nora asks for R7 for 14–16 November | Accepted because Maya checks out on day 14 |
| With R8 booked for 20–22 November, another guest asks for 22–24 November | Accepted because the existing guest checks out on day 22 |
| With R8 booked for 20–22 November, another guest asks for 21–23 November | Unavailable because night 21 is shared |

## R4 · Cancel

A booking can be cancelled. It is kept as Cancelled and no longer blocks the room.

Check: Cancel R101 and search again for 12–14 November.

Proof: `Maya cancels R101: True`, followed by `Free rooms 12-14 Nov: R7, R8`. The verification command also checks that R101 still exists as Cancelled.

## R5 · View

A booking can be looked up by its id.

Check: Look up R101 immediately after Maya books.

Proof: `R101: Maya, R7, 12-14 Nov, Confirmed` in the verification command. The main demo keeps its nine-line output.

## R6 · Failed message

If the confirmation cannot be sent, the booking stays saved and Accepted, and the failure is reported.

Check: Use a fake sender that throws when Maya books R7.

Proof: The R6 test expects `Accepted R101`, `notificationFailed == true`, one confirmed reservation, and R7 still unavailable for that stay.
