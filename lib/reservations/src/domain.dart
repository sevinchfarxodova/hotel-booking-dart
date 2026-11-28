import 'package:hotel_booking/rooms/rooms.dart';

/// A stay includes check-in and excludes check-out (half-open range).
class DateRange {
  const DateRange(this.checkIn, this.checkOut);

  final DateTime checkIn;
  final DateTime checkOut;

  bool isValid() => checkOut.isAfter(checkIn);

  /// Two stays overlap when they share at least one night.
  bool overlaps(DateRange other) =>
      checkIn.isBefore(other.checkOut) && other.checkIn.isBefore(checkOut);
}

class Guest {
  const Guest(this.name, this.email);

  final String name;
  final String email;
}

enum ReservationStatus { confirmed, cancelled }

class Reservation {
  Reservation(this.id, this.guest, this.room, this.stay);

  final String id;
  final Guest guest;
  final Room room;
  final DateRange stay;
  ReservationStatus _status = ReservationStatus.confirmed;
  ReservationStatus get status => _status;

  bool blocks(Room room, DateRange stay) =>
      status == ReservationStatus.confirmed &&
      this.room == room &&
      this.stay.overlaps(stay);

  bool cancel() {
    if (_status == ReservationStatus.cancelled) return false;
    _status = ReservationStatus.cancelled;
    return true;
  }
}
