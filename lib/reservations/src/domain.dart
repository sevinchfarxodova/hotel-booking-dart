class DateRange {
  DateRange(this.checkIn, this.checkOut) {
    if (!checkOut.isAfter(checkIn)) {
      throw ArgumentError('checkOut must be after checkIn');
    }
  }

  final DateTime checkIn;
  final DateTime checkOut;

  int get nights => checkOut.difference(checkIn).inDays;

  bool overlaps(DateRange other) {
    return checkIn.isBefore(other.checkOut) && other.checkIn.isBefore(checkOut);
  }

  static DateRange parse(String checkInStr, String checkOutStr) {
    final ci = DateTime.parse(checkInStr);
    final co = DateTime.parse(checkOutStr);
    return DateRange(DateTime.utc(ci.year, ci.month, ci.day), DateTime.utc(co.year, co.month, co.day));
  }

  String get checkInIso => _fmt(checkIn);
  String get checkOutIso => _fmt(checkOut);

  static String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class Guest {
  const Guest({required this.name, required this.email});

  final String name;
  final String email;
}

enum ReservationStatus { confirmed, cancelled }

class Reservation {
  Reservation({
    required this.id,
    required this.roomId,
    required this.guest,
    required this.stay,
    this.status = ReservationStatus.confirmed,
  });

  final String id;
  final String roomId;
  final Guest guest;
  final DateRange stay;
  ReservationStatus status;

  Map<String, dynamic> toJson() => {
        'id': id,
        'roomId': roomId,
        'guestName': guest.name,
        'guestEmail': guest.email,
        'checkIn': stay.checkInIso,
        'checkOut': stay.checkOutIso,
        'status': status.name,
      };
}
