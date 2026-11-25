import 'domain.dart';

abstract interface class ReservationStore {
  int get count;
  bool hasOverlap(Room room, DateRange stay);
  void save(Reservation reservation);
  Reservation? find(String id);
}

// Keeps reservations in a list. A later practice replaces it with a database.
class InMemoryReservationStore implements ReservationStore {
  final List<Reservation> _rows = [];

  @override
  int get count => _rows.length;

  @override
  bool hasOverlap(Room room, DateRange stay) => _rows.any((row) => row.blocks(room, stay));

  @override
  void save(Reservation reservation) => _rows.add(reservation);

  // Returns null when no reservation has that id.
  @override
  Reservation? find(String id) {
    for (final row in _rows) {
      if (row.id == id) return row;
    }
    return null;
  }

  int countConfirmed(Room room, DateRange stay) =>
      _rows.where((row) => row.blocks(room, stay)).length;
}
