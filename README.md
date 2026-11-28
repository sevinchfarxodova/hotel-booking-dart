# P06 · Hotel booking in Dart

P06 refactors the P04/P05 hotel booking app into a modular monolith with four business modules: Rooms, Reservations, Payments and Notifications. Each module has a public contract; implementation details live under `lib/<module>/src/`. The behavior remains the same, and three architecture tests guard the module boundaries.

Use Dart 3 or later.

```sh
dart pub get
dart analyze
dart test
dart run bin/main.dart
dart run bin/main.dart --race
```

The test suite contains the eight P04 booking behavior tests and three P06 architecture tests. The demo prints the same nine lines as P04. Race mode deliberately continues to reproduce the double-booking gap; the course fixes it in P09.

- [Context definitions](docs/contexts.md)
- [Design notes](docs/design-notes.md)
- [P06 modular-monolith decision](docs/adr-001-modular-monolith.md)
- [Requirements and expected behavior](docs/requirements.md)
- [Editable diagrams](docs/diagrams.drawio) — P05 pages plus the new **Modules** page
- [Modules diagram preview](docs/modules.png)

The module structure is:

```text
lib/
├── rooms/          rooms.dart · src/catalog.dart
├── reservations/   reservations.dart · src/booking.dart, domain.dart, store.dart
├── payments/       payments.dart · src/simulated.dart
└── notifications/  notifications.dart · src/email.dart, sms.dart
```

`bin/main.dart` is the composition root and is the only application source file that constructs internal adapters. Tests may construct them to arrange fixtures.
