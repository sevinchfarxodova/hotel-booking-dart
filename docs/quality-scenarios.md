# Quality scenarios

## Stakeholders

| Who | What they care about |
| --- | --- |
| Guest | Finds a free room quickly and keeps their confirmed booking. |
| Receptionist | Can book and cancel at the desk without promising the same room twice. |
| Hotel manager (domain expert) | Defines room, booking, and deposit rules and chooses the confirmation channels. |
| Development team | Can change one business area without changing unrelated areas. |
| Email/SMS and payment providers | Can respond slowly or be unavailable. Their failures must be visible to the app. |

## S1 · Performance

| Part | Scenario |
| --- | --- |
| Source | Guests using the booking service |
| Stimulus | 200 guests search for free rooms for November 12–14. |
| Environment | Requests arrive within one minute during normal operations. |
| Artifact | Availability search, including catalog and reservation reads |
| Response | Return the correct free rooms for each request. |
| Measure | All 200 responses are correct and p95 response time is at most 1 second. |
| Checked in | P08 (cache) and P23 (load test) |

## S2 · Data integrity

| Part | Scenario |
| --- | --- |
| Source | 100 pairs of guests |
| Stimulus | Both guests in each pair request the same room and overlapping nights at the same time. |
| Environment | Each pair starts with its requested room and nights free. |
| Artifact | Booking operation and reservation storage |
| Response | Confirm one request and reject the competing request as unavailable. |
| Measure | Exactly 1 confirmed reservation per pair and 0 double bookings across 100 pairs. |
| Checked in | P09 |

## S3 · Availability

| Part | Scenario |
| --- | --- |
| Source | Email provider |
| Stimulus | The provider stops answering confirmation requests. |
| Environment | A 10-minute outage during normal bookings. |
| Artifact | `BookingService.reserve()` and the notification sender |
| Response | Save and accept every otherwise valid booking and report its failed confirmation. |
| Measure | 0 lost valid bookings and 100% of failed confirmation attempts reported. |
| Checked in | P04 (R6, single-booking case) and P10 |

## S4 · Security

| Part | Scenario |
| --- | --- |
| Source | A signed-in guest |
| Stimulus | The guest tries 100 times to view a reservation belonging to another guest. |
| Environment | Normal operation with access control enabled. |
| Artifact | Reservation lookup and ownership check |
| Response | Refuse the read without revealing any reservation details. |
| Measure | 0 unauthorized reservation disclosures in 100 attempts. |
| Checked in | P21 |

## S5 · Modifiability

| Part | Scenario |
| --- | --- |
| Source | Hotel manager |
| Stimulus | Requests SMS as a second confirmation channel. |
| Environment | The development team extends the existing email design. |
| Artifact | Notification interface, adapters, and tests |
| Response | Plug in an SMS sender and verify it through the existing booking service. |
| Measure | 0 edits to `BookingService` and at most 2 changed files for the SMS sender and its test. |
| Checked in | P04 |

## S6 · Sustainability

| Part | Scenario |
| --- | --- |
| Source | Development team measuring an availability change |
| Stimulus | Run the same 1,000 searches before and after the change. |
| Environment | Same hardware, dataset, and workload on both runs. |
| Artifact | Availability service, its database, and its cache when enabled |
| Response | Complete the same workload with correct results and lower energy use. |
| Measure | At least 20% fewer watt-hours per 1,000 completed searches. |
| Checked in | P08 and P24 |
