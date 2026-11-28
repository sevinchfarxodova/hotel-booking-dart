import 'dart:async';
import '../../rooms/rooms.dart';
import 'domain.dart';

abstract interface class ReservationStore {
  FutureOr<int> get count;
  FutureOr<bool> hasOverlap(Room room, DateRange stay);
  FutureOr<void> save(Reservation reservation);
  FutureOr<Reservation?> find(String id);
  FutureOr<int> countConfirmed(Room room, DateRange stay);
}

class InMemoryReservationStore implements ReservationStore {
  final Map<String, Reservation> _reservations = {};

  @override
  int get count => _reservations.length;

  @override
  bool hasOverlap(Room room, DateRange stay) {
    for (final r in _reservations.values) {
      if (r.roomId == room.id &&
          r.status == ReservationStatus.confirmed &&
          r.stay.overlaps(stay)) {
        return true;
      }
    }
    return false;
  }

  @override
  void save(Reservation reservation) {
    _reservations[reservation.id] = reservation;
  }

  @override
  Reservation? find(String id) => _reservations[id];

  @override
  int countConfirmed(Room room, DateRange stay) {
    var total = 0;
    for (final r in _reservations.values) {
      if (r.roomId == room.id &&
          r.status == ReservationStatus.confirmed &&
          r.stay.overlaps(stay)) {
        total++;
      }
    }
    return total;
  }
}
