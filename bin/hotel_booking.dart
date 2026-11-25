// P03 · Hotel booking, first version: one file, everything kept in memory.
// dart run bin/hotel_booking.dart          -> the normal demo
// dart run bin/hotel_booking.dart --race   -> two guests book the same room at the same moment

// The stay: check-in day included, check-out day excluded (half-open).
class DateRange {
  DateRange(this.checkIn, this.checkOut);

  final DateTime checkIn;
  final DateTime checkOut;

  bool isValid() => checkOut.isAfter(checkIn);

  // Two stays overlap when they share at least one night.
  bool overlaps(DateRange other) =>
      checkIn.isBefore(other.checkOut) && other.checkIn.isBefore(checkOut);
}

class Guest {
  Guest(this.name, this.email);

  final String name;
  final String email;
}

class Room {
  Room(this.number, this.type);

  final String number;
  final String type;

  // Dart compares objects by identity until a class says what equal means.
  @override
  bool operator ==(Object other) => other is Room && other.number == number;

  @override
  int get hashCode => number.hashCode;
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

  // A reservation blocks a request when it is still Confirmed for the same room and shares a night.
  bool blocks(Room room, DateRange stay) =>
      status == ReservationStatus.confirmed && this.room == room && this.stay.overlaps(stay);

  bool cancel() {
    if (status == ReservationStatus.cancelled) return false;
    _status = ReservationStatus.cancelled;
    return true;
  }
}

// Keeps reservations in a list. A later practice replaces it with a database.
class ReservationStore {
  final List<Reservation> _rows = [];

  int get count => _rows.length;

  bool hasOverlap(Room room, DateRange stay) => _rows.any((row) => row.blocks(room, stay));

  void save(Reservation reservation) => _rows.add(reservation);

  // Returns null when no reservation has that id.
  Reservation? find(String id) {
    for (final row in _rows) {
      if (row.id == id) return row;
    }
    return null;
  }

  int countConfirmed(Room room, DateRange stay) =>
      _rows.where((row) => row.blocks(room, stay)).length;
}

// Simulated: sends nothing and needs no network. P04 moves this dependency behind an interface.
class EmailSender {
  int sent = 0;

  void sendConfirmation(Reservation reservation) => sent++;
}

class BookingResult {
  BookingResult(this.outcome, [this.reservationId]);

  final String outcome;
  final String? reservationId;

  // Putting a BookingResult in a $-slot uses this method, the way ToString does in C#.
  @override
  String toString() => reservationId == null ? outcome : '$outcome $reservationId';
}

class BookingService {
  BookingService(this.rooms, this.store, this.email, {this.slowStep = Duration.zero});

  final List<Room> rooms;
  final ReservationStore store;
  final EmailSender email;
  final Duration slowStep;

  List<Room> findFreeRooms(DateRange stay) =>
      rooms.where((room) => !store.hasOverlap(room, stay)).toList();

  Future<BookingResult> reserve(Guest guest, Room room, DateRange stay) async {
    if (!stay.isValid()) return BookingResult('InvalidDates');
    if (store.hasOverlap(room, stay)) return BookingResult('Unavailable');

    // A pause that lets other requests run while this one waits.
    await Future<void>.delayed(slowStep);

    final reservation = Reservation('R${101 + store.count}', guest, room, stay);
    store.save(reservation);
    email.sendConfirmation(reservation);
    return BookingResult('Accepted', reservation.id);
  }

  bool cancel(String reservationId) => store.find(reservationId)?.cancel() ?? false;
}

final r7 = Room('R7', 'Standard');
final r8 = Room('R8', 'Deluxe');
final maya = Guest('Maya', 'maya@example.com');
final omar = Guest('Omar', 'omar@example.com');
final nora = Guest('Nora', 'nora@example.com');

DateRange nov(int checkIn, int checkOut) =>
    DateRange(DateTime.utc(2026, 11, checkIn), DateTime.utc(2026, 11, checkOut));

String names(List<Room> rooms) => rooms.map((room) => room.number).join(', ');

// Dart prints booleans as true/false; the course output says True, so the demo spells it out.
String boolText(bool value) => value ? 'True' : 'False';

Future<void> main(List<String> args) async {
  if (args.contains('--race')) {
    await runRace();
  } else {
    await runDemo();
  }
}

Future<void> runDemo() async {
  final store = ReservationStore();
  final email = EmailSender();
  final service = BookingService([r7, r8], store, email);

  print('Free rooms 12-14 Nov: ${names(service.findFreeRooms(nov(12, 14)))}');
  print('Maya books R7 12-14 Nov: ${await service.reserve(maya, r7, nov(12, 14))}');
  print('Omar books R7 13-15 Nov: ${await service.reserve(omar, r7, nov(13, 15))}');
  print('Nora books R7 14-16 Nov: ${await service.reserve(nora, r7, nov(14, 16))}');
  print('Omar books R8 15-15 Nov: ${await service.reserve(omar, r8, nov(15, 15))}');
  print('Free rooms 12-14 Nov: ${names(service.findFreeRooms(nov(12, 14)))}');
  print('Maya cancels R101: ${boolText(service.cancel('R101'))}');
  print('Free rooms 12-14 Nov: ${names(service.findFreeRooms(nov(12, 14)))}');
  print('Confirmation emails sent: ${email.sent}');
}

Future<void> runRace() async {
  final store = ReservationStore();
  // Each request now spends half a second between checking and saving.
  final service = BookingService(
    [r7, r8],
    store,
    EmailSender(),
    slowStep: const Duration(milliseconds: 500),
  );
  final stay = nov(12, 14);

  print('Maya and Omar both book R7 for 12-14 Nov at the same moment...');
  final mayaRequest = service.reserve(maya, r7, stay);
  final omarRequest = service.reserve(omar, r7, stay);
  final results = await Future.wait([mayaRequest, omarRequest]);

  print('Maya: ${results[0]}');
  print('Omar: ${results[1]}');
  final confirmed = store.countConfirmed(r7, stay);
  print('Confirmed reservations for R7 on 12-14 Nov: $confirmed');
  print(
    confirmed > 1
        ? 'Double booking! Both requests checked before either one saved.'
        : 'Only one guest has R7.',
  );
}
