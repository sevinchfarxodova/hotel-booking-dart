import 'package:hotel_booking/rooms/rooms.dart';

import 'booking.dart';
import 'domain.dart';

/// List-backed store. Kept in src/ so other modules use the ReservationStore contract.
class InMemoryReservationStore implements ReservationStore {
  final List<Reservation> _rows = [];

  @override
  int get count => _rows.length;

  @override
  bool hasOverlap(Room room, DateRange stay) => _rows.any((row) => row.blocks(room, stay));

  @override
  void save(Reservation reservation) => _rows.add(reservation);

  @override
  Reservation? find(String id) {
    for (final row in _rows) {
      if (row.id == id) return row;
    }
    return null;
  }

  @override
  int countConfirmed(Room room, DateRange stay) =>
      _rows.where((row) => row.blocks(room, stay)).length;
}
