# P03 · Hotel booking in Dart

The first version of the course project keeps reservations in memory. Use Dart
3 or later. The project has no external package dependencies.

```sh
dart analyze
dart run bin/hotel_booking.dart
dart run bin/hotel_booking.dart --race
dart run tool/check.dart
```

The normal demo prints the nine lines below.

```text
Free rooms 12-14 Nov: R7, R8
Maya books R7 12-14 Nov: Accepted R101
Omar books R7 13-15 Nov: Unavailable
Nora books R7 14-16 Nov: Accepted R102
Omar books R8 15-15 Nov: InvalidDates
Free rooms 12-14 Nov: R8
Maya cancels R101: True
Free rooms 12-14 Nov: R7, R8
Confirmation emails sent: 2
```

The race mode intentionally produces two accepted bookings. It demonstrates
the gap between the availability check and the save. The course fixes that
concurrency bug in P09.

- [Requirements and expected output](docs/requirements.md)
- [Design notes](docs/design-notes.md)
- [Five editable diagrams](docs/diagrams.drawio) for diagrams.net

The archive includes a Git bundle with the P03 commit and tag. After
extracting it, run `git clone hotel-booking-p03.bundle hotel-booking-dart`
from the extracted directory to restore the repository for P04.
