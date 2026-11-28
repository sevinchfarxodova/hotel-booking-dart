import '../../notifications/notifications.dart';
import '../../rooms/rooms.dart';
import 'domain.dart';
import 'store.dart';

sealed class BookingResult {}

class BookingConfirmed extends BookingResult {
  BookingConfirmed(this.reservation);
  final Reservation reservation;
}

class RoomUnavailable extends BookingResult {
  RoomUnavailable(this.roomId);
  final String roomId;
}

class UnknownRoom extends BookingResult {
  UnknownRoom(this.roomId);
  final String roomId;
}

class BookingService {
  BookingService(this._rooms, this._store, this._notifications);

  final List<Room> _rooms;
  final ReservationStore _store;
  final NotificationSender _notifications;

  Future<List<Room>> availableRooms(DateRange stay) async {
    final available = <Room>[];
    for (final room in _rooms) {
      final overlap = await _store.hasOverlap(room, stay);
      if (!overlap) {
        available.add(room);
      }
    }
    return available;
  }

  Future<BookingResult> book(String roomId, Guest guest, DateRange stay) async {
    Room? target;
    for (final r in _rooms) {
      if (r.id == roomId) {
        target = r;
        break;
      }
    }
    if (target == null) return UnknownRoom(roomId);

    // Always checks the authoritative store (PostgreSQL), never the cache.
    if (await _store.hasOverlap(target, stay)) {
      return RoomUnavailable(roomId);
    }

    final existingCount = await _store.count;
    final id = 'RES-${existingCount + 1}';
    final reservation = Reservation(
      id: id,
      roomId: roomId,
      guest: guest,
      stay: stay,
    );
    await _store.save(reservation);
    _notifications.send(
      Confirmation(
        reservationId: id,
        recipient: guest.email,
        message: 'Confirmed $roomId from ${stay.checkInIso} to ${stay.checkOutIso}',
      ),
    );
    return BookingConfirmed(reservation);
  }

  Future<bool> cancel(String reservationId) async {
    final reservation = await _store.find(reservationId);
    if (reservation == null) return false;
    if (reservation.status == ReservationStatus.cancelled) return true;
    reservation.status = ReservationStatus.cancelled;
    await _store.save(reservation);
    return true;
  }
}
