import 'dart:async';

import 'package:hotel_booking/notifications/notifications.dart';
import 'package:hotel_booking/rooms/rooms.dart';

import 'domain.dart';

/// Storage promise used by BookingService. P07 supports memory and PostgreSQL.
abstract interface class ReservationStore {
  FutureOr<int> get count;
  FutureOr<bool> hasOverlap(Room room, DateRange stay);
  FutureOr<void> save(Reservation reservation);
  FutureOr<Reservation?> find(String id);
  FutureOr<int> countConfirmed(Room room, DateRange stay);
}

class BookingResult {
  const BookingResult(this.outcome, [this.reservationId, this.notificationFailed = false]);

  final String outcome;
  final String? reservationId;
  final bool notificationFailed;

  @override
  String toString() => reservationId == null ? outcome : '$outcome $reservationId';
}

/// Owns booking rules and uses only other modules' public contracts.
class BookingService {
  BookingService(this.rooms, this.store, this.notifications, {this.slowStep = Duration.zero});

  final List<Room> rooms;
  final ReservationStore store;
  final NotificationSender notifications;
  final Duration slowStep;

  Future<List<Room>> findFreeRooms(DateRange stay) async {
    final free = <Room>[];
    for (final room in rooms) {
      if (!await store.hasOverlap(room, stay)) free.add(room);
    }
    return free;
  }

  Future<BookingResult> reserve(Guest guest, Room room, DateRange stay) async {
    if (!stay.isValid()) return const BookingResult('InvalidDates');
    if (await store.hasOverlap(room, stay)) return const BookingResult('Unavailable');

    // P07 preserves the check/save gap so P09 can fix it explicitly.
    await Future<void>.delayed(slowStep);

    final reservation = Reservation('R${101 + (await store.count)}', guest, room, stay);
    await store.save(reservation);
    try {
      notifications.sendConfirmation(Confirmation(
        reservation.id,
        guest.email,
        room.number,
        stay.checkIn,
        stay.checkOut,
      ));
    } catch (_) {
      return BookingResult('Accepted', reservation.id, true);
    }
    return BookingResult('Accepted', reservation.id);
  }

  Future<bool> cancel(String reservationId) async {
    final reservation = await store.find(reservationId);
    return reservation?.cancel() ?? false;
  }
}
