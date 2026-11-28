# Hotel contexts

## Words

| Word | Meaning here | Name in our Dart code |
| --- | --- | --- |
| Guest | The person for whom the room is booked, such as Maya. | `Guest` |
| Room | An inventory item with a stable number such as R7. | `Room.number` |
| Room type | The room category, such as Standard or Deluxe. | `Room.type` |
| Nightly price | The amount charged for one night in a room. | Not in code yet |
| Out of service | A room withheld from sale, for example while it is being repaired. | Not in code yet |
| Stay | The nights from check-in inclusive to check-out exclusive. | `DateRange(checkIn, checkOut)` |
| Reservation | A guest, room, stay, and status assigned an ID such as R101. | `Reservation` |
| Confirmed | The hotel has promised the room to the guest for those nights. | `ReservationStatus.confirmed` |
| Cancelled | The room promise has been withdrawn and its nights freed. | `ReservationStatus.cancelled` |
| Book | Ask to reserve a room for a guest and date range. | `BookingService.reserve()` |
| Cancel | Withdraw a reservation while keeping its record. | `BookingService.cancel()` |
| Free rooms | Sellable rooms with no conflicting confirmed stay. | `BookingService.findFreeRooms()` |
| Deposit | The upfront portion of the stay price, set at 30% in the future design. | Not in code yet |
| Paid | The deposit charge succeeded. | Not in code yet |
| Declined | The deposit charge was refused. | Not in code yet |
| Confirmation message | An email or SMS telling the guest their room is booked. | `NotificationSender.sendConfirmation()` |
| Sent | A confirmation attempt succeeded. | Not in code yet as a message status |
| Failed | A confirmation attempt failed and its failure should be reported. | Not in code yet as a message status. P04 reports `BookingResult.notificationFailed`. |

## Rooms

**Job** — Keep the hotel’s room inventory and decide which rooms are offered.

| Word | Meaning here |
| --- | --- |
| Room | A catalog entry identified by room number. |
| Room type | A category such as Standard or Deluxe. |
| Nightly price | The amount charged per night according to room type. |
| Out of service | A room the hotel has withdrawn from sale. |

**Rules this context owns**

- **4.** Rooms out of service are excluded from the guest offer.
- **5.** Room type determines nightly price. Deluxe costs more than Standard.

**Needs from other contexts** — Nothing on this map.

**Tells other contexts** — Returns room numbers and types when Reservations asks for the catalog.

## Reservations

**Job** — Decide whether a guest can book a room for a stay and maintain the reservation record.

| Word | Meaning here |
| --- | --- |
| Guest | The person attached to the booking. |
| Stay | The check-in inclusive and check-out exclusive range. |
| Reservation | A guest’s booking for a room number and stay, with an ID and status. |
| Confirmed | The reservation blocks the room for those nights. |
| Cancelled | The stored reservation no longer blocks the room. |
| Book | Request a reservation for a guest, room, and stay. |
| Cancel | Take an existing reservation out of effect and retain its history. |
| Free rooms | Rooms available after subtracting overlapping confirmed stays from the offered inventory. |

**Rules this context owns**

- **1.** Two confirmed reservations for the same room cannot share a night.
- **2.** Check-out must be after check-in.
- **3.** Cancelling a reservation releases its nights.

**Needs from other contexts** — Room numbers and types from Rooms. Starting in P17, a Paid or Declined outcome from Payments.

**Tells other contexts** — Announces `ReservationConfirmed` to Notifications after saving. Sends a deposit request to Payments in P17.

## Payments

**Job** — Take deposits and record payment outcomes.

| Word | Meaning here |
| --- | --- |
| Deposit | A charge for 30% of the stay price. |
| Paid | A successful deposit charge. |
| Declined | An unsuccessful deposit charge. |

**Rules this context owns**

- **6.** Deposit equals 30% of the stay price.
- **7.** Only a Paid deposit can be refunded.

**Needs from other contexts** — A deposit request with its reservation ID and amount. Room pricing is a Rooms-owned input to future pricing work and has no separate border on this map.

**Tells other contexts** — Returns Paid or Declined to Reservations in P17.

## Notifications

**Job** — Tell guests what happened by email or SMS and report delivery failures.

| Word | Meaning here |
| --- | --- |
| Confirmation message | Guest-facing notice that the reservation was accepted. |
| Sent | Delivery attempt succeeded. |
| Failed | Delivery attempt failed and the outcome is reported. |

**Rules this context owns**

- **8.** Record a failed message as Failed while leaving the reservation’s state untouched. In P04 the booking result reports the failure under R6.

**Needs from other contexts** — The five fields in the `ReservationConfirmed` event.

**Tells other contexts** — Reports delivery failure to the caller as required by R6. No callback to Reservations or separate event is on the map.

## Same word, different meaning

| Word | Rooms | Reservations | Payments | Notifications |
| --- | --- | --- | --- | --- |
| Room | The catalog entry and its type, service state, and price. | The room number used to check clashes and record a booking. | No room model is needed to charge the supplied amount. | The room number shown in a confirmation. |
| Status | In service / out of service | Confirmed / Cancelled | Paid / Declined | Sent / Failed |
| Cancel | Withdraw a room from sale, such as during repairs. | Withdraw the promise for an existing reservation. | Reverse a paid charge with a refund when allowed. | Stop an unsent message when the channel supports it. |

If one shared status allowed a failed SMS to replace Maya’s Confirmed status with Failed, Maya could lose her room and the app would break R6.

## Rule owners

| Card | Rule | Owner | Why this owner |
| --- | --- | --- | --- |
| 1 | A room never has two Confirmed reservations that share a night. | Reservations | It holds the room numbers, dates, and status of all bookings. |
| 2 | Check-out must be after check-in. | Reservations | It defines and validates the stay. |
| 3 | Cancelling frees the reservation’s nights. | Reservations | It owns cancellation and knows which reservation states block a night. |
| 4 | A room out of service is excluded from offers. | Rooms | Inventory knows which rooms can be sold. |
| 5 | Deluxe costs more per night than Standard. | Rooms | Inventory owns room types and their nightly prices. |
| 6 | The deposit is 30% of the stay price. | Payments | It owns the percentage and deposit calculation. Nightly prices come from Rooms. |
| 7 | Only a Paid deposit can be refunded. | Payments | It has the authoritative deposit state. |
| 8 | A failed message is recorded as Failed and cannot change the reservation. | Notifications | It owns message delivery and its outcomes. Reservations owns booking state. |

## Between contexts

### Reservations → Rooms · Which rooms exist?

- **Sent when** — Reservations needs the catalog for room search or booking.
- **What Reservations sends** — A request for the room catalog with no payload fields.
- **The answer and its fields** — A list of entries with `roomNumber: String` and `roomType: String`, for example R7 Standard and R8 Deluxe.
- **Never crosses** — Rooms’ private catalog storage, internal pricing records, or the complete Reservations model. Reservations calculates availability from its own bookings.

### Reservations → Payments · Take a deposit (from P17)

- **Sent when** — The future workflow requires a deposit for a booking.
- **What Reservations sends** — `reservationId: String` and the deposit `amount` as a monetary value.
- **The answer and its fields** — One `outcome`, either Paid or Declined.
- **Never crosses** — Guest records, complete reservations, payment credentials, or internal provider records.

### Reservations → Notifications · ReservationConfirmed

- **Sent when** — A confirmed reservation has been saved.
- **What Reservations announces** — `reservationId: String`, `guestEmail: String`, `roomNumber: String`, `checkIn: DateTime`, and `checkOut: DateTime`.
- **The answer and its fields** — The event expects no business reply. In the in-process Dart adapter a send failure can be reported by throwing. R6 keeps the booking accepted.
- **Never crosses** — The `Reservation` object, reservation storage, rate details, or permission to update reservation status.

P04 still passes a `Reservation` to the sender. In P06, Notifications will define its own `Confirmation` value carrying these five fields.
