# P04 · Hotel booking in Dart

P04 refactors the hotel-booking project around reservation storage and notification interfaces. The app still uses in-memory storage and simulated notifications. If delivery fails, the saved booking remains accepted and the result reports the failure.

Use Dart 3 or later. The test dependency is downloaded on first setup.

```sh
dart pub get
dart analyze
dart test
dart run bin/main.dart
dart run bin/main.dart --race
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

The editable draw.io file includes the original five P03 pages and the new
**Classes - after** page. A PNG preview of that page is included in the ZIP.

The Git bundle preserves the P03 and P04 commits and tags. Continue P05 from
the P04 commit on the same course repository.
