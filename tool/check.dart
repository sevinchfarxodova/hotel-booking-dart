import '../bin/hotel_booking.dart';

void check(bool condition, String description) {
  if (!condition) throw StateError(description);
}

Future<void> main() async {
  final store = ReservationStore();
  final email = EmailSender();
  final service = BookingService([r7, r8], store, email);
  final dates = nov(12, 14);

  check(names(service.findFreeRooms(dates)) == 'R7, R8', 'R1 initial search');
  final first = await service.reserve(maya, r7, dates);
  check(first.toString() == 'Accepted R101', 'R2 reserve');

  final saved = store.find('R101');
  if (saved == null) throw StateError('R5 missing R101');
  check(saved.guest == maya && saved.room == r7 &&
      saved.stay.checkIn == dates.checkIn && saved.stay.checkOut == dates.checkOut &&
      saved.status == ReservationStatus.confirmed, 'R5 lookup');
  print('${saved.id}: ${saved.guest.name}, ${saved.room.number}, '
      '${saved.stay.checkIn.day}-${saved.stay.checkOut.day} Nov, Confirmed');

  check((await service.reserve(omar, r7, nov(13, 15))).outcome ==
      'Unavailable', 'R3 partial overlap');
  check((await service.reserve(nora, r7, nov(14, 16))).toString() ==
      'Accepted R102', 'R3 adjacent dates');
  check((await service.reserve(omar, r8, nov(15, 15))).outcome ==
      'InvalidDates', 'R3 zero nights');
  check((await service.reserve(omar, r8, nov(16, 15))).outcome ==
      'InvalidDates', 'R3 reversed dates');
  check(email.sent == 2, 'Only accepted bookings send confirmations');
  check(names(service.findFreeRooms(dates)) == 'R8', 'R1 occupied room hidden');

  check(service.cancel('R101'), 'R4 first cancellation');
  check(!service.cancel('R101'), 'R4 repeated cancellation');
  check(!service.cancel('missing'), 'R4 unknown reservation');
  check(store.find('R101')?.status == ReservationStatus.cancelled &&
      names(service.findFreeRooms(dates)) == 'R7, R8', 'R4 history and availability');

  final raceStore = ReservationStore();
  final race = BookingService([r7, r8], raceStore, EmailSender());
  await Future.wait([race.reserve(maya, r7, dates), race.reserve(omar, r7, dates)]);
  check(raceStore.countConfirmed(r7, dates) == 2, 'P03 race is reproducible');
  print('P03 checks passed.');
}
