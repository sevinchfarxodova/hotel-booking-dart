import 'package:hotel_booking/notifications/notifications.dart';
import 'package:hotel_booking/rooms/rooms.dart';

import 'domain.dart';

/// Storage promise used by BookingService. P07 can replace the list with PostgreSQL.
abstract interface class ReservationStore {
  int get count;
  bool hasOverlap(Room room, DateRange stay);
  void save(Reservation reservation);
  Reservation? find(String id);
  int countConfirmed(Room room, DateRange stay);
}

class BookingResult {
  const BookingResult(this.outcome, [this.reservationId, this.notificationFailed = false]);

  final String outcome;
  final String? reservationId;
  final bool notificationFailed;

  @override
  String toString() => reservationId == null ? outcome : '$outcome $reservationId';
}

/// Owns the booking rules and uses only other modules' public contracts.
class BookingService {
  BookingService(this.rooms, this.store, this.notifications, {this.slowStep = Duration.zero});

  final List<Room> rooms;
  final ReservationStore store;
  final NotificationSender notifications;
  final Duration slowStep;

  List<Room> findFreeRooms(DateRange stay) =>
      rooms.where((room) => !store.hasOverlap(room, stay)).toList();

  Future<BookingResult> reserve(Guest guest, Room room, DateRange stay) async {
    if (!stay.isValid()) return const BookingResult('InvalidDates');
    if (store.hasOverlap(room, stay)) return const BookingResult('Unavailable');

    // P06 keeps the P03/P04 race visible; P09 will close this check/save gap.
    await Future<void>.delayed(slowStep);

    final reservation = Reservation('R${101 + store.count}', guest, room, stay);
    store.save(reservation);
    try {
      notifications.sendConfirmation(Confirmation(
        reservation.id,
        guest.email,
        room.number,
        stay.checkIn,
        stay.checkOut,
      ));
    } catch (_) {
      // A failed notification does not roll back a booking that was already saved.
      return BookingResult('Accepted', reservation.id, true);
    }
    return BookingResult('Accepted', reservation.id);
  }

  bool cancel(String reservationId) => store.find(reservationId)?.cancel() ?? false;
}
